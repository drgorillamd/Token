'use strict';

/**
 * @module TruffleCostReporter
 * Forked form https://github.com/mochajs/mocha/blob/master/lib/reporters/spec.js
 */

/**
 * Module dependencies.
 */

var Base = require('mocha').reporters.Base;
var inherits = require('mocha').utils.inherits;
var color = Base.color;

/**
 * Handles Truffle tests.
 */
const truffleCost = require('truffle-cost');

/**
 * Expose `TruffleCostReporter`.
 */

exports = module.exports = TruffleCostReporter;

/**
 * Initialize a new `TruffleCostReporter` test reporter.
 *
 * @public
 * @class
 * @memberof Mocha.reporters
 * @extends Mocha.reporters.Base
 * @param {Runner} runner
 */
function TruffleCostReporter(runner) {
  Base.call(this, runner);

  var self = this;
  var indents = 0;
  var n = 0;

  function indent() {
    return Array(indents).join('  ');
  }

  // Little trick to use Mocha's colors.
  // Let me know your opinion on ranges!
  function gasColor(gasUsed) {
    if (gasUsed < 100000) {
      return 'green';
    } else if (gasUsed > 4700000) {
      return 'slow';
    } else {
      return 'medium';
    }
  }

  runner.on('start', function() {
    console.log();
    truffleCost.reset();
  });

  runner.on('suite', function(suite) {
    ++indents;
    console.log(color('suite', '%s%s'), indent(), suite.title);
  });

  runner.on('suite end', function() {
    --indents;
    if (indents === 1) {
      console.log();
    }
  });

  runner.on('pending', function(test) {
    var fmt = indent() + color('pending', '  - %s');
    console.log(fmt, test.title);
  });

  runner.on('pass', function(test) {
    var fmt;
    if (!truffleCost.result().gasUsed) {
      fmt =
        indent() +
        color('checkmark', '  ' + Base.symbols.ok) +
        color('pass', ' %s');
      console.log(fmt, test.title);
    } else if (!truffleCost.result().fiatCost) {
      fmt =
        indent() +
        color('checkmark', '  ' + Base.symbols.ok) +
        color('pass', ' %s') +
        color(gasColor(truffleCost.result().gasUsed), ' (%d gas used)');
      console.log(fmt, test.title, truffleCost.result().gasUsed);
    } else {
      fmt =
        indent() +
        color('checkmark', '  ' + Base.symbols.ok) +
        color('pass', ' %s') +
        color(gasColor(truffleCost.result().gasUsed), ' (%d gas used, %d %s)');
      console.log(
        fmt,
        test.title,
        truffleCost.result().gasUsed,
        truffleCost.result().fiatCost,
        truffleCost.result().fiatSymbol
      );
    }
    truffleCost.reset();
  });

  runner.on('fail', function(test) {
    console.log(indent() + color('fail', '  %d) %s'), ++n, test.title);
  });

  runner.once('end', self.epilogue.bind(self));
}

/**
 * Inherit from `Base.prototype`.
 */
inherits(TruffleCostReporter, Base);

TruffleCostReporter.description = 'hierarchical & verbose [default]';
