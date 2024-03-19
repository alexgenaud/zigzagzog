# zigzagzog
Tic-Tac-Toe in Zig

Minimax cannot be defeated. Just try not to lose.

## Build and play

```
% sh build.sh
% ./main
```

Select first player black (yes) or white (no).

Select moves by number (0-8):

```
 0 | 1 | 2
 3 | 4 | 5
 6 | 7 | 8
```

or by left keys or by right keys:

```
 q | w | e          u | i | o
 a | s | d          j | k | l
 z | x | c          m | , | .
```

## About

Builds a minimax tree,
whose scores are accessed by
board transform keys.


```
(c) 2024 Alexander E Genaud

Permission is granted hereby,
to copy, share, use, modify,
   for purposes any,
   for free or for money,
provided these rhymes catch eye.

This work "as is" I provide,
no warranty express or implied,
   for, no purpose fit,
   'tis unmerchantable shit.
Liability for damages denied.
```

## Example game

```
% ./main
Play first as X?: no
You have selected no

X |   |
  |   |
  |   |

Select your move: s

X |   |
  | O |
  |   |

X | X |
  | O |
  |   |

Select your move: e

X | X | O
  | O |
  |   |

X | X | O
  | O |
X |   |

Select your move: a

X | X | O
O | O |
X |   |

X | X | O
O | O | X
X |   |

Select your move: x

X | X | O
O | O | X
X | O |

X | X | O
O | O | X
X | O | X

It's a tie!
```
