PromiseRunner = require('../');

var fns = {
  // Alternative 1: Defined as pure function
  one: function(){return(1);},
  // Alternative 2: Defined as Array
  two: [function(one){ return(2 * one); }, 'one'],
  // Alternative 3: Defined as Object
  three: {
    fn: function(one, two){ return(one + two); },
    deps: ['one', 'two']
  }
};

result = new PromiseRunner().run(fns);
result.then(console.log);
// [1, 2, 3]
