'reach 0.1';
'use strict';
// -----------------------------------------------
// Name: Binary Voting Interface
// Description:  Binary Voting NP Reach App
// Author: Nicholas Shellabarger
// Version: 0.0.9 - add start/end secs
// Requires Reach v0.1.7 (stable)
// ----------------------------------------------
export const Participants = () => [
  Participant('Alice', {
    getParams: Fun([], Object({
      startSecs: UInt,
      endSecs: UInt,
      once: Bool
    }))
  }),
  Participant('Relay', {})
]
export const Views = () => [
  View({
    yes: UInt,
    no: UInt,
    closed: Bool, // common
    startSecs: UInt, // common
    endSecs: UInt // common
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

const next = (c, l) =>
  c == l 
    ? [0, 0]
    : l == VOTE_NONE
      ? c == VOTE_YES
        ? [1, 0]
        : c == VOTE_NO 
          ? [0, 0]
          : [0, 1]
      : c > l
        ? [2, 1]
        : [1, 2]

// TODO: add start seconds for Voting sessions start in 2days 10hours ...
export const App = (map) => {
  const [_, [Alice, Relay], [v], [a]] = map
  Alice.only(() => {
    const { startSecs, endSecs, once } = declassify(interact.getParams())
    assume(startSecs < endSecs)
  })
  Alice.publish(startSecs, endSecs, once)
  require(startSecs < endSecs)
  Relay.set(Alice)
  v.yes.set(0)
  v.no.set(0)
  v.closed.set(false)
  v.startSecs.set(startSecs)
  v.endSecs.set(endSecs)
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
    .invariant(balance() == 0)
    .while(keepGoing)
    .api(a.vote,
      ((yn) => assume(true
        && lastConsensusSecs() > startSecs
        && lastConsensusSecs() < endSecs
        && yn != fromSome(votesM[this], VOTE_NONE)
        && yn == VOTE_YES || yn == VOTE_NO
        && (!once || fromSome(votesM[this], VOTE_NONE) == VOTE_NONE)
      )),
      ((_) => 0),
      ((c, k) => {
        const l = fromSome(votesM[this], VOTE_NONE)
        require(true
          && lastConsensusSecs() > startSecs
          && lastConsensusSecs() < endSecs
          && c != l
          && c == VOTE_YES || c == VOTE_NO
          && (!once || l == VOTE_NONE)
        )
        k(null)
        if(true
          && lastConsensusSecs() > startSecs
          && lastConsensusSecs() < endSecs
          && c != l
          && c == VOTE_YES || c == VOTE_NO
          && (!once || l == VOTE_NONE)) {
          const [na, nb] = next(c, l)
          votesM[this] = c
          return [
            true,
            na == 2 ? (isub(int(Pos, as), +1)).i : as + na,
            nb == 2 ? (isub(int(Pos, bs), +1)).i : bs + nb,
          ]
        } else {
          return [
            true,
            as,
            bs
          ]
        }
      }))
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
      (() => assume(true
        && lastConsensusSecs() >= endSecs
      )),
      (() => 0),
      ((k) => {
        require(true
          && lastConsensusSecs() >= endSecs)
        k(null)
        return [
          false,
          as,
          bs
        ]
      }))
    .timeout(false)
  v.closed.set(true)
  commit()
  Relay.publish()
  commit()
  exit()
}
// ----------------------------------------------
