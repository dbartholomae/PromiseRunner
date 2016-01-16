PromiseRunner = require('../');

var fns = {
  // Alternative 2: Defined as Array
  two: function(one){ return(2 * one); },
  // Alternative 3: Defined as Object
  three: {
    fn: function(two, one){ return(one + two); },
    deps: ['two']
  }
};

result = new PromiseRunner().run(fns, 1);
result.then(console.log);
// [2, 3]