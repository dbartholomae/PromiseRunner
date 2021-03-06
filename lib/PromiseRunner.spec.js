// Generated by CoffeeScript 1.10.0
(function() {
  var Promise, PromiseRunner;

  Promise = require('bluebird');

  PromiseRunner = require('./PromiseRunner');

  describe("A PromiseRunner", function() {
    it("runs tasks", function() {
      var tasks;
      tasks = {
        three: {
          fn: function(one, two) {
            return one + two;
          },
          deps: ['one', 'two']
        },
        one: function() {
          return 1;
        },
        two: [
          function(one) {
            return Promise.resolve(2 * one);
          }, 'one'
        ]
      };
      return expect(new PromiseRunner().run(tasks)).to.eventually.deep.equal([1, 2, 3]);
    });
    it("runs tasks with additional shared arguments", function() {
      var tasks;
      tasks = {
        five: {
          fn: function(two, one) {
            return 2 * two + one;
          },
          deps: ['two']
        },
        two: function(one) {
          return Promise.resolve(2 * one);
        }
      };
      return expect(new PromiseRunner().run(tasks, 1)).to.eventually.deep.equal([2, 5]);
    });
    it("rejects if there is a dependency cycle", function() {
      var tasks;
      tasks = {
        a: [
          (function() {
            return void 0;
          }), 'b'
        ],
        b: [
          (function() {
            return void 0;
          }), 'a'
        ]
      };
      return expect(new PromiseRunner().run(tasks)).to.eventually.be.rejectedWith('Dependency Cycle Found');
    });
    return it("throws an error if tasks are not defined", function() {
      return expect(function() {
        return new PromiseRunner().run();
      }).to["throw"]("No tasks defined");
    });
  });

}).call(this);
