#!/usr/bin/env node

import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { basename } from 'node:path'

const endpoint = 'https://api.monday.com/v2'
const fileEndpoint = 'https://api.monday.com/v2/file'
const apiVersion = '2024-10'
const config = JSON.parse(
  readFileSync(new URL('../config.json', import.meta.url), 'utf8')
)

const fail = (message) => {
  console.error(`monday: ${message}`)
  process.exit(1)
}

const keychainServices = ['monday-api-token', 'MONDAY_API_TOKEN']

const readKeychain = (service) => {
  try {
    return execFileSync('security', ['find-generic-password', '-s', service, '-w'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim()
  } catch {
    return ''
  }
}

const readToken = () => {
  for (const service of keychainServices) {
    const token = readKeychain(service)

    if (token) return token
  }

  if (process.env.MONDAY_API_TOKEN) return process.env.MONDAY_API_TOKEN

  return fail(
    'No Monday token found. Store one with:\n' +
      '  security add-generic-password -s monday-api-token -a "$USER" -w\n' +
      'or export MONDAY_API_TOKEN.'
  )
}

const request = async (query, variables = {}) => {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'API-Version': apiVersion,
      Authorization: readToken(),
    },
    body: JSON.stringify({ query, variables }),
  })

  const payload = await response.json()

  if (payload.errors) fail(JSON.stringify(payload.errors, null, 2))

  if (payload.error_message) fail(payload.error_message)

  return payload.data
}

const readLabels = (settings) => {
  try {
    const parsed = JSON.parse(settings || '{}')

    if (!parsed.labels) return null

    return Object.entries(parsed.labels)
      .map(([index, label]) => `${index}=${label}`)
      .join(', ')
  } catch {
    return null
  }
}

const describe = async (boardId) => {
  const data = await request(
    `query ($ids: [ID!]) {
      boards(ids: $ids) {
        id
        name
        groups { id title }
        columns { id title type settings_str }
      }
    }`,
    { ids: [boardId] }
  )

  const board = data.boards?.[0]

  if (!board) fail(`No board visible with id ${boardId}`)

  console.log(`Board ${board.id}: ${board.name}\n`)
  console.log('Groups:')
  board.groups.forEach((group) => console.log(`  ${group.id}\t${group.title}`))

  console.log('\nColumns:')
  board.columns.forEach((column) => {
    console.log(`  ${column.id}\t${column.type}\t${column.title}`)

    const labels = readLabels(column.settings_str)

    if (labels) console.log(`      labels: ${labels}`)
  })
}

const list = async (boardId, limit = '25') => {
  const data = await request(
    `query ($ids: [ID!], $limit: Int!) {
      boards(ids: $ids) {
        items_page(limit: $limit) {
          items {
            id
            name
            group { title }
            column_values { id text }
          }
        }
      }
    }`,
    { ids: [boardId], limit: Number(limit) }
  )

  const items = data.boards?.[0]?.items_page?.items ?? []

  items.forEach((item) => {
    const fields = item.column_values
      .filter((column) => column.text)
      .map((column) => `${column.id}=${column.text}`)
      .join(' | ')

    console.log(`${item.id}\t[${item.group.title}]\t${item.name}`)

    if (fields) console.log(`\t${fields}`)
  })
}

const get = async (itemId) => {
  const data = await request(
    `query ($ids: [ID!]) {
      items(ids: $ids) {
        id
        name
        group { title }
        column_values { id text }
        updates { id body created_at creator { name } }
      }
    }`,
    { ids: [itemId] }
  )

  const item = data.items?.[0]

  if (!item) fail(`No ticket visible with id ${itemId}`)

  console.log(`${item.id}: ${item.name}  [${item.group.title}]\n`)

  item.column_values
    .filter((column) => column.text)
    .forEach((column) => console.log(`  ${column.id}: ${column.text}`))

  item.updates.forEach((update) => {
    console.log(
      `\n--- update ${update.id} · ${update.creator.name} @ ${update.created_at}`
    )
    console.log(update.body)
  })
}

const ticketUrl = (boardId, itemId) =>
  `https://accommodation-for-students-team.monday.com/boards/${boardId}/pulses/${itemId}`

const create = async ({ boardId, groupId, title, bodyPath, columnsPath }) => {
  const requestedColumns = columnsPath
    ? JSON.parse(readFileSync(columnsPath, 'utf8'))
    : {}
  const columnValues = JSON.stringify({
    status: { label: config.defaultStatus },
    ...requestedColumns,
  })

  const created = await request(
    `mutation ($board: ID!, $group: String, $name: String!, $columns: JSON) {
      create_item(
        board_id: $board
        group_id: $group
        item_name: $name
        column_values: $columns
      ) { id }
    }`,
    {
      board: boardId,
      group: groupId || config.defaultGroupId,
      name: title,
      columns: columnValues,
    }
  )

  const itemId = created.create_item.id

  if (bodyPath) await comment(itemId, bodyPath)

  console.log(itemId)
  console.log(ticketUrl(boardId, itemId))
}

const escapeHtml = (text) =>
  text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

const inlineMarkup = (text) =>
  escapeHtml(text)
    .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')

const preserveIndentation = (code) =>
  code.replace(/^ +/gm, (indent) => '&nbsp;'.repeat(indent.length))

const markdownToHtml = (markdown) => {
  const blocks = markdown.split(/```/)

  return blocks
    .map((block, index) => {
      if (index % 2 === 1) {
        const withoutLanguage = block
          .replace(/^[a-z]*\n/, '')
          .replace(/^\n+|\s+$/g, '')

        return `<pre>${preserveIndentation(escapeHtml(withoutLanguage))}</pre>`
      }

      return block
        .split(/\n{2,}/)
        .map((paragraph) => paragraphToHtml(paragraph.trim()))
        .filter(Boolean)
        .join('\n')
    })
    .join('\n')
}

const paragraphToHtml = (paragraph) => {
  if (!paragraph) return ''

  if (/^-{3,}$/.test(paragraph)) return '<br><hr><br>'

  const heading = paragraph.match(/^(#{1,4})\s+(.*)$/)

  if (heading) {
    const level = Math.min(heading[1].length + 1, 5)

    return `<h${level}>${inlineMarkup(heading[2])}</h${level}>`
  }

  const lines = paragraph.split('\n')

  if (lines.every((line) => /^\s*[-*]\s+/.test(line))) {
    const items = lines
      .map((line) => `<li>${inlineMarkup(line.replace(/^\s*[-*]\s+/, ''))}</li>`)
      .join('')

    return `<ul>${items}</ul>`
  }

  if (lines.every((line) => /^\s*\d+\.\s+/.test(line))) {
    const items = lines
      .map((line) => `<li>${inlineMarkup(line.replace(/^\s*\d+\.\s+/, ''))}</li>`)
      .join('')

    return `<ol>${items}</ol>`
  }

  return `<p>${lines.map(inlineMarkup).join('<br>')}</p>`
}

const readBody = (bodyPath) => {
  const source = readFileSync(bodyPath, 'utf8')

  return bodyPath.endsWith('.md') ? markdownToHtml(source) : source
}

const comment = async (itemId, bodyPath) => {
  const body = readBody(bodyPath)

  await request(
    `mutation ($item: ID!, $body: String!) {
      create_update(item_id: $item, body: $body) { id }
    }`,
    { item: itemId, body }
  )
}

const attach = async (updateId, filePath) => {
  if (!/^\d+$/.test(updateId)) fail(`update id must be numeric: ${updateId}`)

  const form = new FormData()
  form.append(
    'query',
    `mutation ($file: File!) {
      add_file_to_update(update_id: ${updateId}, file: $file) { id }
    }`
  )
  form.append(
    'variables[file]',
    new Blob([readFileSync(filePath)]),
    basename(filePath)
  )

  const response = await fetch(fileEndpoint, {
    method: 'POST',
    headers: { 'API-Version': apiVersion, Authorization: readToken() },
    body: form,
  })

  const payload = await response.json()

  if (payload.errors) fail(JSON.stringify(payload.errors, null, 2))

  if (payload.error_message) fail(payload.error_message)

  console.log(payload.data.add_file_to_update.id)
}

const boardIdOf = async (itemId) => {
  const data = await request(
    `query ($ids: [ID!]) {
      items(ids: $ids) { board { id } }
    }`,
    { ids: [itemId] }
  )

  const boardId = data.items?.[0]?.board?.id

  if (!boardId) fail(`No ticket visible with id ${itemId}`)

  return boardId
}

const rename = async (itemId, title) => {
  const boardId = await boardIdOf(itemId)

  await request(
    `mutation ($item: ID!, $board: ID!, $name: String!) {
      change_simple_column_value(
        item_id: $item
        board_id: $board
        column_id: "name"
        value: $name
      ) { id }
    }`,
    { item: itemId, board: boardId, name: title }
  )
}

const attachedFileNames = async (updateId) => {
  const data = await request(
    `query ($ids: [ID!]) {
      updates(ids: $ids) { assets { name } }
    }`,
    { ids: [updateId] }
  )

  return (data.updates?.[0]?.assets ?? []).map((asset) => asset.name)
}

const editUpdate = async (updateId, bodyPath, reattachPaths) => {
  const attached = await attachedFileNames(updateId)
  const reattachNames = reattachPaths.map((filePath) => basename(filePath))
  const missing = attached.filter((name) => !reattachNames.includes(name))

  if (missing.length > 0) {
    fail(
      `update ${updateId} has attached files that editing would remove: ${missing.join(', ')}\n` +
        'Pass them to re-attach: edit-update <updateId> <bodyFile> <file> [file...]'
    )
  }

  const body = readBody(bodyPath)

  await request(
    `mutation ($update: ID!, $body: String!) {
      edit_update(id: $update, body: $body) { id }
    }`,
    { update: updateId, body }
  )

  for (const filePath of reattachPaths) await attach(updateId, filePath)
}

const setColumns = async (itemId, columnsPath) => {
  const columnValues = JSON.parse(readFileSync(columnsPath, 'utf8'))

  if ('status' in columnValues) {
    fail('Changing status is not wired up. Move the ticket on the board instead.')
  }

  const boardId = await boardIdOf(itemId)

  await request(
    `mutation ($item: ID!, $board: ID!, $columns: JSON!) {
      change_multiple_column_values(
        item_id: $item
        board_id: $board
        column_values: $columns
      ) { id }
    }`,
    { item: itemId, board: boardId, columns: JSON.stringify(columnValues) }
  )
}

const [command, ...args] = process.argv.slice(2)

if (command === 'describe') {
  if (!args[0]) fail('usage: monday.mjs describe <boardId>')

  await describe(args[0])
} else if (command === 'list') {
  if (!args[0]) fail('usage: monday.mjs list <boardId> [limit]')

  await list(args[0], args[1])
} else if (command === 'get') {
  if (!args[0]) fail('usage: monday.mjs get <itemId>')

  await get(args[0])
} else if (command === 'create') {
  const [boardId, groupId, title, bodyPath, columnsPath] = args

  if (!boardId || !title) {
    fail(
      'usage: monday.mjs create <boardId> <groupId|""> <title> [bodyFile] [columnsJsonFile]'
    )
  }

  await create({ boardId, groupId, title, bodyPath, columnsPath })
} else if (command === 'comment') {
  const [itemId, bodyPath] = args

  if (!itemId || !bodyPath) fail('usage: monday.mjs comment <itemId> <bodyFile>')

  await comment(itemId, bodyPath)

  console.log(itemId)
} else if (command === 'rename') {
  const [itemId, title] = args

  if (!itemId || !title) fail('usage: monday.mjs rename <itemId> <title>')

  await rename(itemId, title)

  console.log(itemId)
} else if (command === 'edit-update') {
  const [updateId, bodyPath, ...reattachPaths] = args

  if (!updateId || !bodyPath) {
    fail('usage: monday.mjs edit-update <updateId> <bodyFile> [file...]')
  }

  await editUpdate(updateId, bodyPath, reattachPaths)

  console.log(updateId)
} else if (command === 'set-columns') {
  const [itemId, columnsPath] = args

  if (!itemId || !columnsPath) {
    fail('usage: monday.mjs set-columns <itemId> <columnsJsonFile>')
  }

  await setColumns(itemId, columnsPath)

  console.log(itemId)
} else if (command === 'attach') {
  const [updateId, ...filePaths] = args

  if (!updateId || filePaths.length === 0) {
    fail('usage: monday.mjs attach <updateId> <file> [file...]')
  }

  for (const filePath of filePaths) await attach(updateId, filePath)
} else {
  fail(
    'usage: monday.mjs describe|list|get|create|comment|rename|edit-update|set-columns|attach ...'
  )
}
