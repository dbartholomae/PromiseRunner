Promise = require 'bluebird'
DepGraph = require('dependency-graph').DepGraph
winston = require 'winston'

# A PromiseRunner runs multiple functions that are dependent on each other in the correct order.
# Tasks are defined as an object `{ taskName: task, ... }`, with `task` being either a function
# that has no dependencies, an array where the first element is the function and the rest are
# the names of tasks it depends on, or an object `{ fn: function, deps: [string] }`.
# Each task will be run with the results of its dependencies as parameters.
# Tasks can either return values or promises that return their values.
module.exports = class PromiseRunner
  isFunction = (obj) -> typeof obj is 'function'
  isArray = (obj) -> Object.prototype.toString.call(obj) is "[object Array]"

  # Convert different function and array form of task definition to object form
  # @param tasks [Object] An object with tasks
  # @return Tasks of the form { fn: function, deps: [string] }
  parseTasks = (tasks) ->
    for taskName, task of tasks
      winston.debug 'Parsing task ' + taskName
      if isFunction task
        winston.debug ' Parsing from function'
        tasks[taskName] =
          fn: task
      else if isArray task
        winston.debug ' Parsing from array'
        tasks[taskName] =
          fn: task[0]
          deps: task[1..]

      unless tasks[taskName].deps?
        winston.debug ' Adding empty dependency array'
        tasks[taskName].deps = []

    return tasks

  # Determine the order in which to run the tasks
  # @param tasks [Object] Tasks of the form { fn: function, deps: [string] }
  # @return [Array<String>] The tasks in correct order
  # @throw "Dependency Cycle Found"
  determineOrder = (tasks) ->
    winston.debug "Determining order of tasks " + Object.keys tasks
    graph = new DepGraph()
    for taskName, task of tasks
      winston.debug " Adding task " + taskName + " to dependency graph"
      graph.addNode taskName
      for dep in task.deps
        winston.debug "  Adding dependency " + dep + " of task " + taskName
        graph.addNode dep
        graph.addDependency taskName, dep
    return graph.overallOrder()

  cache = {}

  # Load all dependencies for a task run it and add it to the cache.
  # @param taskName [String] The name of the task to load
  load = (taskName, tasks) ->
    if cache[taskName]?
      winston.debug "Loading task " + taskName + " from cache"
      return cache[taskName]

    winston.debug "Loading task " + taskName + " by running it"
    cache[taskName] = Promise.all tasks[taskName].deps
    .map (dep) ->
      winston.debug "  Loading dependency " + dep + " of task " + taskName
      load dep, tasks
    .then (arr) ->
      winston.debug "  Dependencies for task " + taskName + " loaded, running task"
      tasks[taskName].fn arr...

  # Create a new PromiseRunner
  constructor: (options) ->
    options ?= {}
    @options =
      debug: options.debug?

    ### !pragma coverage-skip-next ###
    if @options.debug
      winston.level = 'debug'

  # Run a set of tasks and return a promise that resolves when all are run and rejects
  # with "Dependency Cycle Found" if there is a dependency cycle.
  # @param tasks [object] task definitions
  # @return [Promise] A promise resolving when all tasks where run
  # @throw [Error("No tasks defined")] if tasks is undefined
  run: (tasks) ->
    throw new Error "No tasks defined" unless tasks?
    winston.debug "Preparing to run tasks " + Object.keys tasks
    tasks = parseTasks(tasks)
    winston.debug "Tasks parsed"
    try
      order = determineOrder tasks
    catch error
      return Promise.reject error
    winston.debug "Order determined: " + order
    return Promise.all order
    .map (task) ->
      load task, tasks
