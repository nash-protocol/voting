import { loadStdlib } from "@reach-sh/stdlib";
import launchToken from "@reach-sh/stdlib/launchToken.mjs";
import assert from "assert";

const [, , infile] = process.argv;

(async () => {
  console.log("START");

  const backend = await import(`./build/${infile}.main.mjs`);
  const stdlib = await loadStdlib();
  const startingBalance = stdlib.parseCurrency(100);

  const accAlice = await stdlib.newTestAccount(startingBalance);
  const accBob = await stdlib.newTestAccount(startingBalance);
  const accs = await Promise.all(
    Array.from({ length: 10 }).map(() => stdlib.newTestAccount(startingBalance))
  );
  //await stdlib.wait(10)

  const zorkmid = await launchToken(stdlib, accAlice, "zorkmid", "ZMD");

  const getBalance = async (who) =>
    stdlib.formatCurrency(await stdlib.balanceOf(who), 4);

  const beforeAlice = await getBalance(accAlice);
  const beforeBob = await getBalance(accBob);

  const getParams = (addr) => ({
    addr,
    addr2: addr,
    addr3: addr,
    addr4: addr,
    addr5: addr,
    amt: stdlib.parseCurrency(1),
    tok: zorkmid.id,
    token_name: "",
    token_symbol: "",
    secs: 0,
    secs2: 0,
  });

  const signal = () => {};

  const voteHelper = (ctc) => async (vote) =>
    ((v) => ctc.a.vote(v))(vote === "yes" ? 1 : 2);

  const getVoteHelper = (ctc) => async (vote) =>
    stdlib.bigNumberToNumber((await ctc.v[vote]())[1]);

  // (1) can be deleted before activation
  console.log("CAN DELETED INACTIVE");
  (async (acc) => {
    let addr = acc.networkAccount.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
        signal,
      }),
      backend.Verifier(ctc, {}),
    ]).catch(console.dir);
    let appId = await ctc.getInfo();
    console.log(appId);
  })(accAlice);
  await stdlib.wait(4);

  // (2) constructor receives payment on activation
  console.log("CAN ACTIVATE WITH PAYMENT");
  await (async (acc, acc2) => {
    let addr = acc.networkAccount.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
        signal,
      }),
    ]);
    let appId = await ctc.getInfo();
    console.log(appId);
    let ctc2 = acc2.contract(backend, appId);
    Promise.all([backend.Contractee(ctc2, {})]);
    await stdlib.wait(50);
  })(accAlice, accBob);

  const afterAlice = await getBalance(accAlice);
  const afterBob = await getBalance(accBob);

  const diffAlice = Math.round(afterAlice - beforeAlice);
  const diffBob = Math.round(afterBob - beforeBob);

  console.log(
    `Alice went from ${beforeAlice} to ${afterAlice} (${diffAlice}).`
  );
  console.log(`Bob went from ${beforeBob} to ${afterBob} (${diffBob}).`);

  assert.equal(diffAlice, 1);
  assert.equal(diffBob, -1);

  // alice can vote yes
  console.log("CAN VOTE AND UPDATE");
  await (async (acc, acc2, accs) => {
    let addr = acc.networkAccount.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
        signal,
      }),
    ]);
    let appId = await ctc.getInfo();
    console.log(appId);
    let ctc2 = acc2.contract(backend, appId);
    Promise.all([
      backend.Contractee(ctc2, {}),
      backend.Alice(ctc2, {
        getParams: () => ({
          secs: new Date().getTime() * 2,
          once: false,
        }),
      }),
    ]);
    await stdlib.wait(100);
    const getVote = getVoteHelper(ctc);
    const voteAlice = voteHelper(ctc);
    const voteBob = voteHelper(ctc2);
    // alice before voting
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote("yes"), 0);
    assert.equal(await getVote("no"), 0);
    // alice votes yes
    await voteAlice("yes").catch(console.dir);
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote("yes"), 1);
    assert.equal(await getVote("no"), 0);
    // alice updates vote to no
    await voteAlice("no").catch(console.dir);
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 0)
    assert.equal(await getVote('no'), 1)
    await voteBob("yes").catch(console.dir);
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 1)
    assert.equal(await getVote('no'), 1)
    await voteBob("no").catch(console.dir);
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 0)
    assert.equal(await getVote('no'), 2)
    for (let i in accs) {
      let acc = accs[i];
      const ctc = acc.contract(backend, appId);
      const vote = voteHelper(ctc);
      if (Math.round(Math.random()) + 1 > 1) {
        await vote("no").catch(console.dir);
      } else {
        await vote("yes").catch(console.dir);
      }
    }
    stdlib.wait(100);
    console.log(await getVote("yes"), await getVote("no"));
  })(accAlice, accBob, accs);

  // alice can vote yes
  console.log("CAN VOTE ONCE");
  await (async (acc, acc2, accs) => {
    let addr = acc.networkAccount.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
        signal,
      }),
    ]);
    let appId = await ctc.getInfo();
    console.log(appId);
    let ctc2 = acc2.contract(backend, appId);
    Promise.all([
      backend.Contractee(ctc2, {}),
      backend.Alice(ctc2, {
        getParams: () => ({
          secs: new Date().getTime() * 2,
          once: true,
        }),
      }),
    ]);
    await stdlib.wait(100);
    const getVote = getVoteHelper(ctc);
    const voteAlice = voteHelper(ctc);
    const voteBob = voteHelper(ctc2);
    // alice before voting
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote("yes"), 0);
    assert.equal(await getVote("no"), 0);
    // alice votes yes
    await voteAlice("yes")
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote("yes"), 1);
    assert.equal(await getVote("no"), 0);
    // alice updates vote to no
    await voteAlice("no").catch(()=>{})
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 1)
    assert.equal(await getVote('no'), 0)
    await voteBob("yes")
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 2)
    assert.equal(await getVote('no'), 0)
    await voteBob("no").catch(()=>{})
    console.log(await getVote("yes"), await getVote("no"));
    assert.equal(await getVote('yes'), 2)
    assert.equal(await getVote('no'), 0)
    for (let i in accs) {
      let acc = accs[i];
      const ctc = acc.contract(backend, appId);
      const vote = voteHelper(ctc);
      if (Math.round(Math.random()) + 1 > 1) {
        await vote("no")
      } else {
        await vote("yes")
      }
    }
    stdlib.wait(100);
    console.log(await getVote("yes"), await getVote("no"));
  })(accAlice, accBob, accs);

  // TODO add first voter on expired session
  // TODO add last voter on expired session
  // TODO add attempts to close contract before end of session
  // TODO add touch
  process.exit();
})();
