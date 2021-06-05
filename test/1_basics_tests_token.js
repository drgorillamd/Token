const Token = artifacts.require("iBNB");

contract("Token", accounts => {

  it("Initialized - return proper name()", async () => {

    const x = await Token.deployed();
    const obs_name = await x.name();
    assert.equal(obs_name, "PlayBIT.gg", "incorrect name returned")
  });

  it("deployer = owner", async () => {

    const x = await Token.deployed();
    const owned_by = await x.owner.call();
    assert.equal(accounts[0], owned_by, "Owner is not account[0]");
  });

  it("transfer from owner/exempted", async () => {
    const to_send = 10**6;
    const to_receive = 10**6;
    const sender = accounts[0];
    const receiver = accounts[1];
    const meta = await Token.deployed();

    await meta.transfer(receiver, to_send, { from: sender });

    const newBal = await meta.balanceOf.call(receiver);

    assert.equal(newBal.toNumber(), to_receive, "incorrect amount transfered");
  });

  it("transfer standard", async () => {
    const to_send = 10**6;
    const to_receive = 10**6 - (10**6 * 134/1000);
    const sender = accounts[1];
    const receiver = accounts[2];
    const meta = await Token.deployed();

    await meta.transfer(receiver, to_send, { from: sender });

    const newBal = await meta.balanceOf.call(receiver);

    assert.equal(newBal.toNumber(), to_receive, "incorrect amount transfered");
  });



});
