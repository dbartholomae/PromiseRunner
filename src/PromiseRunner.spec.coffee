Promise = require 'bluebird'
PromiseRunner = require './PromiseRunner'

describe "A PromiseRunner", ->
  it "runs tasks", ->
    tasks = {
      three:
        fn: (one, two) -> one + two
        deps: ['one', 'two']
      one: -> 1
      two: [
        (one) -> Promise.resolve 2 * one
        'one'
      ]
    }
    expect(new PromiseRunner().run(tasks)).to.eventually.deep.equal [1, 2, 3]

  it "runs tasks with additional shared arguments", ->
    tasks = {
      five:
        fn: (two, one) -> 2 * two + one
        deps: ['two']
      two: (one) -> Promise.resolve 2 * one
    }
    expect(new PromiseRunner().run(tasks, 1)).to.eventually.deep.equal [2, 5]

  it "rejects if there is a dependency cycle", ->
    tasks = {
      a: [(-> undefined), 'b']
      b: [(-> undefined), 'a']
    }
    expect(new PromiseRunner().run(tasks))
    .to.eventually.be.rejectedWith 'Dependency Cycle Found'

  it "throws an error if tasks are not defined", ->
    expect(-> new PromiseRunner().run()).to.throw "No tasks defined"
