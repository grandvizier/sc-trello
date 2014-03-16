supervisor = require 'supervisor'

supArgs = [
  '--watch', '.'

  # Watch these extensions
  # note: 'smart_dev_restart' task reacts differently to each ext.
  '--extensions', 'jade,styl,coffee|js|css'

  '-x', 'coffee'
  'route.coffee'
]

supervisor.run supArgs