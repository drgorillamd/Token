const Token = artifacts.require("iBNB");
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const routerContract = artifacts.require('IUniswapV2Router02');
const pairContract = artifacts.require('IUniswapV2Pair');
const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";


contract("Token", accounts => {

  before(async function() {
    const x = await Token.new(routerAddress);
  });

  describe("Adding Liq", () => {
    it("Circuit Breaker: Enabled", async () => {
      const x = await Token.deployed();
      await x.setCircuitBreaker(true, {from: accounts[0]});
      const status_circ_break = await x.circuit_breaker.call();
      assert.equal(true, status_circ_break, "Circuit breaker not set");
    });

    it("Router testing", async () => {
      const x = await Token.deployed();
      const router = await routerContract.at(routerAddress);
      assert.notEqual(0, await router.WETH.call(), "router down");
    });

    it("Adding liquidity: 10^8 token & 4BNB", async () => {
      const amount_BNB = 4*10**18;
      const amount_token = 10**8;
      const sender = accounts[0];

      const x = await Token.deployed();
      const router = await routerContract.at(routerAddress);
      let _ = await x.approve(routerAddress, amount_token);
      await router.addLiquidityETH(x.address, amount_token, 0, 0, accounts[0], 1907352278, {value: amount_BNB}); //9y from now. Are you from the future? Did we make it?

      const pairAdr = await x.pair.call();
      const pair = await pairContract.at(pairAdr);
      const LPBalance = await pair.balanceOf.call(accounts[0]);

      assert.notEqual(LPBalance.toNumber(), 0, "No LP token received");
    });

    it("Circuit Breaker: Disabled", async () => {

      const x = await Token.deployed();
      await x.setCircuitBreaker(false, {from: accounts[0]});
      const status_circ_break = await x.circuit_breaker.call();
      assert.equal(false, status_circ_break, "Circuit breaker not set");
    });
  });


  //[ 0         2,       4,       6,        8        revert]    Sell tax(%)
  //[   0.0125,    250,     500,      750,     1000]	    	    Tranche(% of pool bal)
  describe("Regular transfers", () => {
    it("Transfer standard: single -- 1.26m / 0.0126% of pool", async () => {
      const x = await Token.deployed();

      const to_send = 1260000;
      const to_receive = to_send - (to_send * 0.1) - (to_send * 2 / 100); // 10% taxes + sell_tax of 0.0126% of the pool ->2%
      const sender = accounts[1];
      const receiver = accounts[2];

      await truffleCost.log(x.transfer(sender, to_send, { from: accounts[0] }), 'USD');
      await truffleCost.log(x.transfer(receiver, to_send, { from: sender }), 'USD');
      const newBal = await x.balanceOf.call(receiver);
      assert.equal(newBal.toNumber(), to_receive, "incorrect amount transfered");
    });
  });

});
