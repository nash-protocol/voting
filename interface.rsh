'reach 0.1';
'use strict';
// -----------------------------------------------
// Name: Interface Template
// Description: NP Rapp simple
// Author: Nicholas Shellabarger
// Version: 0.0.4 - rename symbols
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
const VOTE_YES = 1
const VOTE_NO = 2
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
        && yn == 1 || yn == 2
      )),
      ((_) => 0),
      ((yn, k) => {
        const last = fromSome(votesM[this], 0)
        require(true
          && lastConsensusSecs() < secs
          && yn != last
          && yn == 1 || yn == 2)
        const newAs = yn != VOTE_YES ? as
          : as + 1 + (last != VOTE_YES ? 1 : 0)
        const newBs = yn != VOTE_NO ? bs
          : bs + 1 + (last != VOTE_NO ? 1 : 0)
        votesM[this] = yn
        k(null)
        return [
          true,
          newAs,
          newBs
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
