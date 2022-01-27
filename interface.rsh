'reach 0.1';
'use strict';
// -----------------------------------------------
// Name: Binary Voting Interface
// Description:  Binary Voting NP Reach App
// Author: Nicholas Shellabarger
// Version: 0.0.5 - use enum, refactor
// Requires Reach v0.1.7 (stable)
// ----------------------------------------------
export const Participants = () => [
  Participant('Alice', {
    getParams: Fun([], Object({
      secs: UInt
    }))
  }),
  Participant('Relay', {})
]
export const Views = () => [
  View({
    yes: UInt,
    no: UInt
  })
]
export const Api = () => [
  API({
    vote: Fun([UInt], Null),
    close: Fun([], Null),
    touch: Fun([], Null)
  })
]

const [
  _,
  VOTE_NONE,
  VOTE_YES,
  VOTE_NO
] = makeEnum(3)

const nextTally = (curr, last) => (as, expect) =>
  curr != expect
    ? as
    : as + 1 + (last != expect ? 1 : 0)

export const App = (map) => {
  const [ _, { tok }, [Alice, Relay], [v], [a]] = map
  Alice.only(() => {
    const { secs } = declassify(interact.getParams())
  })
  Alice.publish(secs)
  Relay.set(Alice)
  v.yes.set(0)
  v.no.set(0)
  const votesM = new Map(UInt)
  const [
    keepGoing,
    as,
    bs
  ] = parallelReduce([
    true,
    0,
    0
  ])
    .define(() => {
      v.yes.set(as)
      v.no.set(bs)
    })
    .invariant(balance() == 0 && balance(tok) == 0)
    .while(keepGoing)
    .api(a.vote,
      ((yn) => assume(true
        && lastConsensusSecs() < secs
        && yn != fromSome(votesM[this], 0)
        && yn == VOTE_YES || yn == VOTE_NO
      )),
      ((_) => 0),
      ((yn, k) => {
        const last = fromSome(votesM[this], VOTE_NONE)
        require(true
          && lastConsensusSecs() < secs
          && yn != last
          && yn == 1 || yn == 2)
        const nextT = nextTally(yn, last)
        votesM[this] = yn
        k(null)
        return [
          true,
          nextT(as, VOTE_YES),
          nextT(bs, VOTE_NO)
        ]}))
    .api(a.touch,
      (() => 0),
      ((k) => {
        k(null)
        return [
          keepGoing,
          as,
          bs
        ]
      }))
    .api(a.close,
      (() => 0),
      ((k) => {
        k(null)
        return [
          lastConsensusSecs() < secs,
          as,
          bs
        ]
      }))
    .timeout(false)
  commit()
  Relay.publish()
  commit()
  exit()
}
// ----------------------------------------------
