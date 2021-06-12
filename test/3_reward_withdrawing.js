const Token = artifacts.require("iBNB");
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const routerContract = artifacts.require('IUniswapV2Router02');
const pairContract = artifacts.require('IUniswapV2Pair');
const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";


contract("Reward", accounts => {

  const to_send = 10**7;
  const amount_BNB = 98 * 10**18;
  const pool_balance = '1' + '0'.repeat(20);

  before(async function() {
    const x = await Token.new(routerAddress);
  });

  describe("Setting the Scene", () => {

    it("Adding Liq", async () => { //from 2_liqAdd & Taxes
      const x = await Token.deployed();
      await x.setCircuitBreaker(true, {from: accounts[0]});
      const status_circ_break = await x.circuit_breaker.call();
      const router = await routerContract.at(routerAddress);
      const amount_token = pool_balance;
      const sender = accounts[0];

      let _ = await x.approve(routerAddress, amount_token);
      await router.addLiquidityETH(x.address, amount_token, 0, 0, accounts[0], 1907352278, {value: amount_BNB}); //9y from now. Are you from the future? Did we make it?

      const pairAdr = await x.pair.call();
      const pair = await pairContract.at(pairAdr);
      const LPBalance = await pair.balanceOf.call(accounts[0]);

      await x.setCircuitBreaker(false, {from: accounts[0]});

      assert.notEqual(LPBalance, 0, "No LP token received / check Uni pool");
    });

    it("Lowering SwapForLiqThreshold", async () => {
      const x = await Token.deployed();
      await x.setSwapFor_Reward_Threshold(1);
      const val = await x.swap_for_reward_threshold.call();
      assert.equal(val.toNumber(), 1*10**9, "Wrong threshold");
    });


  });

  //tricking the balancer to trigger a swap
  describe("Balancer setting", () => {

    it("Transfer to contract > 2 * swap for reward threshold -100", async () => {
      const x = await Token.deployed();
      await x.transfer(x.address, (2*10**9)-100, { from: accounts[0] });
      const newBal = await x.balanceOf.call(x.address);
      assert.equal(newBal.toNumber(), (2*10**9)-100, "Transfer Failure");
    });

    it("Reset balancer", async () => {
      const x = await Token.deployed();
      await x.resetBalancer({from: accounts[0]});
      const new_bal = await x.balancer_balances.call();
      const subbal = new_bal[0];  //when reset, ratio at 50/50

      assert.equal(subbal.toNumber(), ((2*10**9)-100)/2, "Balancer error");
    });

    it("Reward pool status", async () => {
      const x = await Token.deployed();
      const a = await x.balancer_balances.call();
      const reward_obs_pool = a[0];
      assert.notEqual(reward_obs_pool.toNumber(), 0, "Reward pool failure");
    });
  });

  describe("Reward Mechanics: Swap", () => {
    it("Transfers to trigger swap - wish me luck", async () => {
      const x = await Token.deployed();
      await x.transfer(accounts[1], 10**9, { from: accounts[0] });
      await truffleCost.log(x.transfer(accounts[2], 10**9, { from: accounts[1] }));
      const newBal = await x.balanceOf.call(accounts[2]);
      assert.notEqual(newBal.toNumber(), 0, "Transfer Failure");
    });

    it("BNB balance", async () => {
      const x = await Token.deployed();
      const bal = await web3.eth.getBalance(x.address);
      assert.notEqual(bal, 0, "Swap Failure");
    });
  });


});
