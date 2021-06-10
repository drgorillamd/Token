const Token = artifacts.require("iBNB");
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');

contract("Token", accounts => {

  it("Initialized - return proper name()", async () => {

    const x = await Token.deployed();
    const obs_name = await x.name();
    assert.equal(obs_name, "iBNB", "incorrect name returned")
  });

  it("deployer = owner", async () => {

    const x = await Token.deployed();
    const owned_by = await x.owner.call();
    assert.equal(accounts[0], owned_by, "Owner is not account[0]");
  });

  it("Circuit Breaker: Enabled", async () => {

    const x = await Token.deployed();
    await truffleCost.log(x.setCircuitBreaker(true, {from: accounts[0]}));
    const status_circ_break = await x.circuit_breaker.call();
    assert.equal(true, status_circ_break, "Circuit breaker not set");
  });

  it("Circuit breaker: transfer from owner/exempted", async () => {
    const to_send = 10**6;
    const to_receive = 10**6;
    const sender = accounts[0];
    const receiver = accounts[1];
    const meta = await Token.deployed();

    await truffleCost.log(meta.transfer(receiver, to_send, { from: sender }));

    const newBal = await meta.balanceOf.call(receiver);

    assert.equal(newBal.toNumber(), to_receive, "incorrect amount transfered");
  });

  it("Circuit breaker: transfer standard", async () => {
    const to_send = 10**6;
    const to_receive = 10**6;
    const sender = accounts[1];
    const receiver = accounts[2];
    const meta = await Token.deployed();

    await meta.transfer(receiver, to_send, { from: sender });

    const newBal = await meta.balanceOf.call(receiver);

    assert.equal(newBal.toNumber(), to_receive, "incorrect amount transfered");
  });

  it("Circuit Breaker: Disabled", async () => {

    const x = await Token.deployed();
    await x.setCircuitBreaker(false, {from: accounts[0]});
    const status_circ_break = await x.circuit_breaker.call();
    assert.equal(false, status_circ_break, "Circuit breaker not set");
  });

  it("Circuit Breaker: Unauthorized", async () => {

    const x = await Token.deployed();
    await truffleAssert.reverts(x.setCircuitBreaker(true, {from: accounts[1]}), "Ownable: caller is not the owner.");
  });

});
