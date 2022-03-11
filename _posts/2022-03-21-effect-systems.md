---
title: Effect Systems
categories: [Programming]
tags: [haskell, functional, programming]
---

As I've begun exploring the world of so-called **algebraic effect systems**,
I've become increasingly frustrated in the level of documentation around them.
Learning to use them (and moreso understanding how they work) requires diving
into library internals, watching various videos, and hoping to grok why certain
effects aren't being interpreted the way you might have hoped. My goal in this
post is to address this issue, at least to some degree, in a focused,
pedagogical fashion.

A large portion of this post has been derived from the implementation of the
[fused-effects](https://hackage.haskell.org/package/fused-effects) library,
chosen because it seems to have the most active development, the smallest
dependency footprint, and minimal type machinery. In turn, this library was
largely inspired by Nicolas Wu, Tom Schrijvers, and Ralf Hinze's work in
[Effect Handlers in Scope](https://www.cs.ox.ac.uk/people/nicolas.wu/papers/Scope.pdf).
As such, we'll discuss choice parts of this paper as well.

Code snippets can be found in [this git repository](https://github.com/jrpotter/effect-systems).

{% include toc.html %}

# Free Monads

To begin our exploration, let's pose a few questions:

1. How can we go about converting a simple algebraic data type into a monad?
1. Does there exist some set of minimal requirements the data type must fulfill
to make this conversion "free"?[^1]

To help guide our decision making, we'll examine the internals of some arbitrary
monad. More concretely, let's see what `1 + 2` could look like within a monadic
context:

```haskell
onePlusTwo :: forall m. Monad m => m Int
onePlusTwo = do
  a <- pure 1
  b <- pure 2
  pure $ a + b
```

The above won't win any awards, but it should be illustrative enough for our
purposes. `do` is just syntactic sugar for repeated bind applications (`>>=`),
so we could've written the above alternatively as:

```haskell
onePlusTwo' :: forall m. Monad m => m Int
onePlusTwo' = pure 1 >>= (\a -> pure 2 >>= (\b -> pure (a + b)))
```

This is where we'll pause for a moment and squint. We see that `do` syntax
desugars into something that looks awfully close to a (non-empty) list! Let's
compare the above with how we might define that:

```haskell
data NonEmptyList a = Last a | Cons a (a -> NonEmptyList a)

onePlusTwo'' :: NonEmptyList Int
onePlusTwo'' = Cons 1 (\a -> Cons 2 (\b -> Last (a + b)))

runNonEmptyList :: NonEmptyList Int -> Int
runNonEmptyList (Last a) = a
runNonEmptyList (Cons a f) = runNonEmptyList (f a)

-- >>> runIdentity onePlusTwo'
-- 3
-- >>> runNonEmptyList onePlusTwo''
-- 3
```

Take a moment to appreciate the rough pseudo-equivalence of `NonEmptyList` and a
monad. Also take a moment to appreciate the differences. Because we no longer
employ the bind operator anywhere within our function definitions, we have
effectively separated the **syntax** of our original function from its
**semantics**. That is, `onePlusTwo''` can be viewed as a *program* in and of
itself, and the `runNonEmptyList` **handler** can be viewed as the
interpretation of said program.

## Making a Monad

`NonEmptyList` was formulated from a monad, so it's natural to think perhaps it
too is a monad. Unfortunately this is not the case - it isn't even a functor!
Give it a try or use `{-# LANGUAGE DeriveFunctor #-}` to ask the compiler to
make an attempt on your behalf.

{% include tip.html content="Type variable `a` is said to be contravariant with
respect to `Cons`. That is, `a` resides in a [negative position](https://www.fpcomplete.com/blog/2016/11/covariance-contravariance/)
within `Cons`'s function." %}

If we can't make this a monad as is, are there a minimal number of changes we
could introduce to make it happen? Ideally our changes maintain the "shape" of
the data type as much as possible, thereby maintaining the integrity behind the
original derivation. Since our current roadblock stems from type variable `a`'s
position in `Cons`, let's see what happens if we just abstract it away:

```haskell
data NonEmptyList' f a = Last' a | Cons' a (f (NonEmptyList' f a))
```

With general parameter `f` now in the place of `(->) a`, a functor derivation
becomes possible provided `f` is also a `Functor`:

```haskell
instance (Functor f) => Functor (NonEmptyList' f) where
  fmap f (Last' a) = Last' (fmap f a)
  fmap f (Cons' a ts) = Cons' (f a) (fmap (fmap f) g)
```

And though we needed to modify our syntax and semantics slightly, the proposed
changes do not lose us out on anything of real consequence:

```haskell
twoPlusThree :: NonEmptyList' (Reader Int) Int
twoPlusThree = Cons'
  2 (reader (\a -> Cons'
    3 (reader (\b -> Last' (a + b)))))

runNonEmptyList' :: NonEmptyList' (Reader Int) Int -> Int
runNonEmptyList' (Last' a) = a
runNonEmptyList' (Cons' a f) = runNonEmptyList' (runReader f a)

-- >>> runNonEmptyList' twoPlusThree
-- 5
```

Compare the above snippet with `onePlusTwo'`.

---

The `Applicative` instance is slightly more involved so we'll hold off on that
front for the time-being. For the sake of forging ahead though, assume it
exists. With the `Functor` instance established and the `Applicative` instance
assumed, we are ready to tackle writing the `Monad` instance. A first attempt
would probably look like the following:

```haskell
instance (Functor f) => Monad (NonEmptyList' f) where
  (>>=) :: NonEmptyList' f a -> (a -> NonEmptyList' f b) -> NonEmptyList' f b
  Last' a   >>= g = g a
  Cons' a f >>= g = Cons' _ (fmap (>>= g) f)
```

Defining bind (`>>=`) on `Last'` is straightforward, but `Cons'` again presents
a problem. With `g` serving as our only recourse of converting an `a` into
anything, how should we fill in the hole (`_`)? One approach could be:

```haskell
instance (Functor f) => Monad (NonEmptyList' f) where
  Cons' a f >>= g =
    let ts = fmap (>>= g) f
     in case g a of
          Last' b    -> Cons' b ts
          Cons' b f' -> Cons' b (f' <> ts)
```

but this is pretty unsatisfactory. This definition requires a `Semigroup`
constraint on `f`, which in turn requires some lifting operator. After all, how
else could we append `Last a1 <> Last a2` together? Suddenly the list of
constraints on `f` is growing despite our best intentions. Let's take a step
back and see if there is something else we can try.

The insight falls from the one constraint we had already added (admittedly
without much fanfare). That is, we are requiring type variable `f` to be a
`Functor`! With this in mind, we can actually massage our first parameter into a
bind-compatible one by simply omitting it altogether.

To elaborate, it is [well known](https://bartoszmilewski.com/2015/02/03/functoriality/)
simple algebraic data types are isomorphic to "primitive" functors (`Identity`
and `Const`) and that (co)products of functors yield more functors. We can
therefore "absorb" the syntax of `a` *into* `f` by using a product type as a
container of sorts:

```haskell
data NonEmptyList'' f a = Last'' a | Cons'' (f (NonEmptyList'' f a))

data Container a m k = Container a (m k) deriving Functor

threePlusFour :: NonEmptyList'' (Container Int (Reader Int)) Int
threePlusFour = Cons''
  (Container 3 (reader (\a -> Cons''
    (Container 4 (reader (\b -> Last'' (a + b)))))))

runNonEmptyList'' :: NonEmptyList'' (Container Int (Reader Int)) Int -> Int
runNonEmptyList'' (Last'' a) = a
runNonEmptyList'' (Cons'' (Container a f)) = runNonEmptyList'' (runReader f a)

-- >>> runNonEmptyList'' threePlusFour
-- 7
```

The above demonstrates `NonEmptyList'` was in fact overly specific for our
purposes. By generalizing further still, we lose no expressivity and gain the 
capacity to finally write our `Monad` instance:

```haskell
instance (Functor f) => Monad (NonEmptyList'' f) where
  Last'' a >>= g = g a
  Cons'' f >>= g = Cons'' (fmap (>>= g) f)
```

## Making an Applicative

The `NonEmptyList''` variant actually has another well known name within the
community:

```haskell
data Free f a = Pure a | Free (f (Free f a))
```

We favor this name over `NonEmptyList''` from here on out. In the last section
we deferred writing the `Applicative` instance for `Free` but we can now present
its implementation. First, let's gather some intuition around how we expect it
to work by monomorphizing `Free` over `Maybe` and `Int`:

```haskell
>>> a = Free (Just (Free (Just (Pure (+1)))))
>>> b = Pure 5
>>> c = Free (Just (Pure 5))
```

What should the result of `a <*> b` be? An argument could probably be made for
either:

1. `Free (Just (Free (Just (Pure 6))))`
1. `Pure 6`

What about for `a <*> c`? In this case, any one of the three answers is a
potentially valid possibility:

1. `Free (Just (Free (Just (Free (Just (Pure 6))))))`
1. `Free (Just (Free (Just (Pure 6))))`
1. `Free (Just (Pure 6))`

This ambiguity is why we waited until we finished defining the `Monad` instance.
Instead of trying to reason about which instance makes sense, we choose the
interpretation that aligns with our monad.

```haskell
ap :: forall f a b. Functor f => Free f (a -> b) -> Free f a -> Free f b
ap f g = do
  f' <- f
  g' <- g
  pure (f' g')
```

Examining the results of `ap a b` and `ap a c`, we determine the first entries
of the above two lists must be the answer. Thus it is consistent to define our
`Applicative` like so:

```haskell
instance (Functor f) => Applicative (Free f) where
  pure = Pure

  Pure f <*> g = fmap f g
  Free f <*> g = Free (fmap (<*> g) f)
```

## Algebraic Data Types

Let's revisit our original questions:

> 1. How can we go about converting a simple algebraic data type into a monad?
> 1. Does there exist some set of minimal requirements the data type must
> fulfill to make this conversion "free"?

We have shown that a data type must be a `Functor` for us to build up a `Free`
monad. Additionally, as [mentioned earlier](#making-a-monad), simple algebraic
data types are *already* functors, thereby answering both questions. To drive
this point home, consider the canonical `Teletype` example:

```haskell
data Teletype k = Read k | Write String k deriving Functor
```

Armed with this data type, we can generate programs using the `Teletype` DSL.
For instance,

```haskell
read :: Free Teletype String
read = Free (Read (Pure "hello"))

write :: String -> Free Teletype ()
write s = Free (Write s (Pure ()))

readThenWrite :: Free Teletype ()
readThenWrite = do
  input <- read
  write input
```

Smart constructors `read` and `write` are included to abstract away the
boilerplate and help highlight `readThenWrite`'s role of syntax. Invoking this
function does not actually *do* anything, but reading the function makes it very
obvious what we at least *want* it to do. A corresponding handler provides the
missing semantics:

```haskell
runReadThenWrite :: Free Teletype () -> IO ()
runReadThenWrite (Free (Write s f)) = putStrLn s >> runReadThenWrite f
runReadThenWrite (Free (Read f)) = runReadThenWrite f
runReadThenWrite (Pure _) = pure ()
```

# Composing Effects

Though neither impressive nor particularly flexible, `readThenWrite` is an
example of a DSL corresponding to our `Teletype` **effect**. This is only half
the battle though. As mentioned at the start, we want to be able to compose
effects together within the same program. After all, a program with just one
effect doesn't actually end up buying us much except a lot of unnecessary
abstraction.

As we begin our journey down this road, let's depart from `Teletype` and meet up
with hopefully a familiar friend:

```haskell
data State s k = Get (s -> k) | Put s k
  deriving Functor
```

In the above snippet, `State` has been rewritten from our usual MTL-style to a
pseudo continuation-passing style compatible with `Free`. An example handler
might look like:

```haskell
runState :: forall s a. s -> Free (State s) a -> (s, a)
runState s (Free (Get f)) = runState s (f s)
runState _ (Free (Put s' f)) = runState s' f
runState _ (Pure a) = a
```

We can then run this handler on a sample program like so:

```haskell
increment :: Free (State Int) ()
increment = Free (Get (\s -> Free (Put (s + 1) (Pure ()))))

-- >>> runState 0 increment
-- (1, ())
```

Let's raise the ante a bit. Suppose now we wanted to pass around a second state,
e.g. a `String`. How might we go about doing this? Though we could certainly
rewrite `increment` to have state `(Int, String)` instead of `Int`, this feels
reminiscient to the [expression problem](/posts/tagless-final-parsing#expression-problem).
Having to update and recompile every one of our programs every time we introduce
some new effect is a maintenance burden we should not settle on shouldering.
Instead, we should aim to write all of our programs in a way that doesn't
require modifying source.

## Sum Types

Let's consider what it would take to compose effects `State Int` and
`State String` together. In the world of data types, we usually employ either
products or coproducts to bridge two disjoint types together. Let's try the
latter and see where we end up:

```haskell
data (f :+: g) k = L (f k) | R (g k)
  deriving (Functor, Show)

infixr 4 :+:
```

This allows us to join types in the following manner:

```haskell
>>> L (Just 5) :: (Maybe :+: Identity) Int
L (Just 5)
>>> R (Identity 5) :: (Maybe :+: Identity) Int
R (Identity 5)
```

We call this chain of functors a **signature**. We can compose a signature
containing our `Int` and `String` state as well as a handler capable of
interpreting it:

```haskell
runTwoState
  :: forall s1 s2 a
   . s1
  -> s2
  -> Free (State s1 :+: State s2) a
  -> (s1, s2, a)
runTwoState s1 s2 (Free (L (Get f)))    = runTwoState s1 s2 (f s1)
runTwoState s1 s2 (Free (R (Get f)))    = runTwoState s1 s2 (f s2)
runTwoState _  s2 (Free (L (Put s1 f))) = runTwoState s1 s2 f
runTwoState s1 _  (Free (R (Put s2 f))) = runTwoState s1 s2 f
runTwoState s1 s2 (Pure a)              = (s1, s2, a)
```

It's functional but hardly a solution. It requires manually writing every
combination of effects introduced by `:+:` - a straight up herculean task as the
signature gets longer. It also does not address the "expression problem". That
said, it *does* provide the scaffolding for a more polymorphic solution. We can
bypass this combinatorial explosion of patterns by focusing on just one effect
at a time, parameterizing the remainder of the signature. Handlers can then
"peel" an effect off a signature, over and over, until we are out of effects to
peel:

```haskell
runState' ::
  forall s a sig.
  Functor sig =>
  s ->
  Free (State s :+: sig) a ->
  Free sig (s, a)
runState' s (Pure a) = pure (s, a)
runState' s (Free (L (Get f))) = runState' s (f s)
runState' _ (Free (L (Put s f))) = runState' s f
runState' s (Free (R other)) = Free (fmap (runState' s) other)
```

The above function combines the ideas of `runState` and `runTwoState` into a
more general interface. Now programs containing `State` effects in any order can
be interpreted by properly ordering the handlers:

```haskell
threadedState :: Free (State Int :+: State String) ()
threadedState =
  Free (L (Get (\s1 ->
    Free (R (Get (\s2 ->
      Free (L (Put (s1 + 1)
        (Free (R (Put (s2 ++ "a")
          (Pure ()))))))))))))

threadedState' :: Free (State String :+: State Int) ()
threadedState' = ...

-- >>> runState "" . runState' @Int 0 $ threadedState
-- ("a",(1,()))
-- >>> runState @Int 0 . runState' "" $ threadedState'
-- (1,("a",()))
```

## Membership

We can do better still. Our programs are far too concerned with the ordering of
their corresponding signatures. The only thing they should care about is whether
the effect exists at all. We can relax this coupling by introducing a new
recursive typeclass:

```haskell
class Member sub sup where
  inj :: sub a -> sup a
  prj :: sup a -> Maybe (sub a)
```

Here `sub` is said to be a *subtype* of `sup`. `inj` allows us to promote that
subtype to `sup` and `prj` allows us to dynamically downcast back to `sub`. This
typeclass synergizes especially well with `:+:`. For instance, we expect
`State Int` to be a subtype of `State Int :+: State String`. Importantly, we'd
expect the same for `State String`. Let's consider how instances of `Member`
might look. First is reflexivity:

```haskell
instance Member sig sig where
  inj = id
  prj = Just
```

This instance should be fairly straightforward. We want to be able to cast a
type to and from itself without issue. Next is left-occurrence:

```haskell
instance Member sig (sig :+: r) where
  inj       = L
  prj (L f) = Just f
  prj _     = Nothing
```

This is the pattern we've been working with up until now. Casting upwards is
just a matter of using the `L` data constructor while projecting back down works
so long as we are within the `L` context. Likewise there exists a
right-recursion rule:

```haskell
instance (Member sig r) => Member sig (l :+: r) where
  inj       = R . inj
  prj (R g) = prj g
  prj _     = Nothing
```

Lastly, as a convenience, we introduce left-recursion:

```haskell
instance Member sig (l1 :+: (l2 :+: r)) =>
         Member sig ((l1 :+: l2) :+: r) where
  inj sub = case inj sub of
    L l1     -> L (L l1)
    R (L l2) -> L (R l2)
    R (R r)  -> R r
  prj sup = case sup of
    L (L l1) -> prj (L l1)
    L (R l2) -> prj (R (L l2))
    R r      -> prj (R (R r))
```

The above allows us to operate on a *tree* of types rather than a list. We can
read this as saying "subtying is not affected by how `:+:` is associated."

{% include warning.html content="These instances will not compile as is. A mix
of `TypeApplications` and `OVERLAPPING` pragmas must be used. Refer to the
[git repository](https://github.com/jrpotter/effect-systems) for the real
implementation." %}

With the above instances in place, we can now create a more flexible
implementation of `threadedState` above:

```haskell
data Void k deriving Functor

run :: forall a. Free Void a -> a
run (Pure a) = a
run _ = error (pack "impossible")

threadedState'' ::
  Functor sig =>
  Member (State Int) sig =>
  Member (State String) sig =>
  Free sig ()
threadedState'' =
  Free (inj (Get @Int (\s1 ->
    Free (inj (Get (\s2 ->
      Free (inj (Put (s1 + 1)
        (Free (inj (Put (s2 ++ "a")
          (Pure ()))))))))))))

-- >>> run . runState' "" . runState' @Int 0 $ threadedState''
-- ("a",(1,()))
-- >>> run . runState' @Int 0 . runState' "" $ threadedState''
-- (1,("a",()))
```

A few takeaways:

1. The program now stays polymorphic in type `sig`,
1. We no longer explicitly mention `L` or `R` data constructors, and
1. We use `run` to peel away the final effect.

This flexibility grants us the ability to *choose* the order we handle effects
at the call site. By writing a few additional smart constructors, we could have
a nicer program still:

```haskell
inject :: (Member sub sup) => sub (Free sup a) -> Free sup a
inject = Free . inj

project :: (Member sub sup) => Free sup a -> Maybe (sub (Free sup a))
project (Free s) = prj s
project _        = Nothing

get :: Functor sig => Member (State s) sig => Free sig s
get = inject (Get pure)

put :: Functor sig => Member (State s) sig => s -> Free sig ()
put s = inject (Put s (pure ()))

threadedStateM'' ::
  Functor sig =>
  Member (State Int) sig =>
  Member (State String) sig =>
  Free sig ()
threadedStateM'' = do
  s1 <- get @Int
  s2 <- get @String
  put (s1 + 1)
  put (s2 ++ "a")
  pure ()
```

# Higher-Order Effects

This composition provides many benefits, but in certain situations we end up
hitting a wall. To continue forward, we borrow an example from
[Effect Handlers in Scope](https://www.cs.ox.ac.uk/people/nicolas.wu/papers/Scope.pdf).
In particular, we discuss exception handling and how we can use a free monad to
simulate throwing and catching exceptions.

```haskell
newtype Throw e k = Throw e deriving (Functor)

throw e = inject (Throw e)
```

{% include info.html content="To avoid too many distractions, we will sometimes
skip writing type signatures." %}

This `Throw` type should feel very intuitive at this point. We take an exception
and "inject" it into our program using the `throw` smart constructor. What's the
`catch`?

```haskell
catch (Pure a)             _ = pure a
catch (Free (L (Throw e))) h = h e
catch (Free (R other))     h = Free (fmap (`catch` h) other)
```

In this scenario, `catch` traverses our program, happily passing values through
until it encounters a `Throw`. Our respective "peel" looks like so:

```haskell
runThrow :: forall e a sig. Free (Throw e :+: sig) a -> Free sig (Either e a)
runThrow (Pure a) = pure (Right a)
runThrow (Free (L (Throw e))) = pure (Left e)
runThrow (Free (R other)) = Free (fmap runThrow other)
```

We now have the requisite tools needed to build up and execute a sample program
that composes some `State Int` effect with a `Throw` effect:

```haskell
countDown ::
  forall sig.
  Functor sig =>
  Member (State Int) sig =>
  Member (Throw ()) sig =>
  Free sig ()
countDown = do
  decr {- 1 -}
  catch (decr {- 2 -} >> decr {- 3 -}) pure
 where
  decr = do
    x <- get @Int
    if x > 0 then put (x - 1) else throw ()
```

This program calls a potentially dangerous `decr` function three times, with the
last two attempts wrapped around a `catch`.

## Scoping Problems

How should the state of `countDown` be interpreted? There exist two reasonable
options:

1. If state is considered **global**, then successful decrements in catch should
   persist. That is, our final state would be the initial value decremented
   as many times as `decr` succeeds.
1. If state is considered **local**, we expect `catch` to decrement state twice
   but to *rollback* if an error is raised. If an error is caught, our final
   state would be the initial value decremented just the once.

This is what it means for an operation to be **scoped**. In the local case,
within the semantics of exception handling, the nested program within `catch`
should not affect the state of the world outside of it in the case of an
exception. Let's see if we can somehow write and invoke handlers accordingly:

```haskell
>>> run . runThrow @() . runState' @Int 3 $ countDown
Right (0,())
```

The above snippet demonstrates a result we expect in either interpretation. The
nested `decr >> decr` raises no error. Likewise

```haskell
>>> run . runThrow @() . runState' @Int 0 $ countDown
Left ()
```

should also feel correct, regardless of interpretation. `decr {- 1 -}` ends up
returning a `throw ()` which the subsequent `runThrow` handler interprets as
`Left`. What about the following?

```haskell
>>> run . runThrow @() . runState' @Int 2 $ countDown
Right (0,())
```

This is an example of a global interpretation. Here we throw an error on
`decr {- 3 -}` but `decr {- 2 -}`'s effects persist despite existing within the
`catch`. So can we scope the operation? As it turns out, local semantics are out
of reach. "Flattening" the program hopefully makes the reason clearer:

```haskell
countDown' =
  Free (inj (Get @Int (\x ->
    let a = \k -> if x > 0 then Free (inj (Put (x - 1) k)) else throw ()
     in a (catch (Free (inj (Get @Int (\y ->
      let b = \k -> if y > 0 then Free (inj (Put (y - 1) k)) else throw ()
       in b (Free (inj (Get @Int (\z ->
         let c = \k -> if z > 0 then Free (inj (Put (z - 1) k)) else throw ()
          in c (Pure ()))))))))) pure))))
```

It's noisy, but in the above snippet we see there exists no mechanism that
"saves" the state prior to running the nested program.

## A Stronger Free

Somehow we need to ensure a nested (e.g. the program scoped within `catch`) does
not "leak" in any way. To support programs within programs (within programs
within programs...) within the already recursively defined free monad, we look
towards a higher-level abstraction for help. According to Wu, Schrijvers, and
Hinze,

> A more direct solution [to handle some self-contained context] is to model
> scoping constructs with higher-order syntax, where the syntax carries those
> syntax blocks directly.

What would such a change look like? To answer that, it proves illustrative
understanding why our current definition of `Free` is insufficient. Consider
what it means to "run" our program. We have a handler that traverses the
program, operates on effects it knows how to operate on, and then returns a
slightly less abstract program for the next handler to process. To save state,
we somehow need each handler to refer to a **context** containing state as
defined by the handler prior.

As a starting point, review our current definition of `Free`:

```haskell
data Free f a = Pure a | Free (f (Free f a))
```

We see `a` is not something we, the effects library author, are in a position to
manipulate. To actually extract a value to be saved and threaded in a context
though, we at the very least need this ability. So can we introduce some change
that give us this freedom? One idea is:

```haskell
data Free f a = Pure a | Free (f (Free f) a)
```

The change is subtle but has potential provided we can get all the derived type
machinery working on this type instead. Take note! Previously the kind of `f`
was `Type -> Type`. In this new definition, we see it is now
`(Type -> Type) -> (Type -> Type)`. That is, `f` is now a function that maps
one type function to another. We have entered the world of higher-order kinds.

{% include info.html content="`f` is usually a natural transformation, mapping
one functor to another. The specifics regarding natural transformations aren't
too important here. Just note when we use the term going forward, we mean a
functor to functor mapping." %}

Ideally we can extrapolate our learnings so far to this higher-order world. Of
most importance is our `Functor`-constrained type variable `f`. Let's dive a bit
deeper into what it currently buys us. First, take another look at how `fmap` is
used within `Free`'s `Monad` instance:

```haskell
instance (Functor f) => Monad (Free f) where
  Pure a >>= g = g a
  Free f >>= g = Free (fmap (>>= g) f)
```

Its purpose is to allow *extending* our syntax, chaining different DSL terms
together into a bigger program. When we write e.g.

```haskell
readThenWrite = do
  input <- read
  write input
```

it is `fmap` that is responsible for piecing the `read` and `write` together.
Second, re-examine a sample handler, e.g.

```haskell
runState' s (Pure a)             = pure (s, a)
runState' s (Free (L (Get f)))   = runState' s (f s)
runState' _ (Free (L (Put s f))) = runState' s f
runState' s (Free (R other))     = Free (fmap (runState' s) other)
```

In this case, `fmap` is responsible for *weaving* the state semantics throughout
the syntax. This is what allows us to interpret programs comprised of multiple
different syntaxes. Whatever we end up building at the higher level needs to
keep both these aspects in mind.

### Higher-Order Syntax

Syntax is the easier of the two to resolve so that's where we'll first avert out
attention. Extension requires two things:

1. A higher-level concept of a functor to constrain our new `f`, and
1. An `fmap`-like function capable of performing the extension.

Building out (1) is fairly straightforward. Since `f` corresponds to a natural
transformation, we create a mapping between functors like so:

```haskell
class HFunctor f where
  hmap ::
    (Functor m, Functor n) =>
    (forall x. m x -> n x) ->
    (forall x. f m x -> f n x)
```

This allows us to lift transformations of e.g. `Identity -> Maybe` into
`f Identity -> f Maybe`. Take a moment to notice the parallels between `fmap`
and `hmap`. Building (2) is equally simple:

```haskell
class HFunctor f => Syntax f where
  emap :: (m a -> m b) -> (f m a -> f m b)
```

We designate `emap` as our `fmap`-extending equivalent. This is made obvious by
seeing how `Free` ends up using `emap`:

```haskell
instance Syntax f => Monad (Free f) where
  Pure a >>= g = g a
  Free f >>= g = Free (emap (>>= g) f)
```

Once again, note the parallels betwen the `Monad` instances of both `Free`s.

### Higher-Order Semantics

The more difficult problem lies on the semantic side of the equation. This part
needs to manage the threading of functions throughout potentially nested
effects. To demonstrate, consider a revision to our `Throw` type that includes a
`Catch` at the syntactic level:

```haskell
data Error e m a = Throw e
                 | forall x. Catch (m x) (e -> m x) (x -> m a)
```

We can create `Error` instances of our `HFunctor` and `Syntax` classes as
follows:

```haskell
instance HFunctor (Error e) where
  hmap _ (Throw x) = Throw x
  hmap t (Catch p h k) = Catch (t p) (t . h) (t . k)

instance Syntax (Error e) where
  emap _ (Throw e) = Throw e
  emap f (Catch p h k) = Catch p h (f . k)
```

This is all well and good, but now suppose we want to write a handler in the
same way we wrote `runThrow` earlier:

```haskell
runError ::
  forall e a sig.
  Syntax sig =>
  Free (Error e :+: sig) a ->
  Free sig (Either e a)
runError (Pure a)                 = pure (Right a)
runError (Free (L (Throw e)))     = pure (Left e)
runError (Free (L (Catch p h k))) =
  runError p >>= \case
    Left e ->
      runError (h e) >>= \case
        Left e' -> pure (Left e')
        Right a -> runError (k a)
    Right a -> runError (k a)
runError (Free (R other))         = Free _
```

Make sure everything leading up to the last pattern makes sense and then ask
yourself how you might fill in the hole (`_`). We only have a few tools
at our disposal, namely `hmap` and `emap`. But, no matter how we choose to
compose them, `hmap` will let us down. In particular, our only means of
"peeling" the signature is `runError` which is incompatible with the natural
transformation `hmap` expects.

---

We need another function specific for this weaving behavior, which we choose to
add to the `Syntax` typeclass:

```haskell
class HFunctor f => Syntax f where
  emap :: (m a -> m b) -> (f m a -> f m b)

  weave ::
    (Monad m, Monad n, Functor ctx) =>
    ctx () ->
    Handler ctx m n ->
    (f m a -> f n (ctx a))

type Handler ctx m n = forall x. ctx (m x) -> n (ctx x)
```

Pay special attention to `Handler`. By introducing a functorial context (i.e.
`ctx`), we have defined a function signature that more closely reflects that of
`runError`. This is made clearer by instantiating `ctx` to `Either e`:

```haskell
type Handler m n = forall x. Either e (m x) -> n (Either e x)

runError :: Free (Error e :+: sig) a -> Free sig (Either e a)
```

Without `ctx`, `weave` would look just like `hmap`, highlighting how it's
particularly well-suited to bypassing the `hmap`'s limitations. With `weave`
also comes expanded `Syntax` instances:

```haskell
instance (Syntax f, Syntax g) => Syntax (f :+: g) where
  weave ctx hdl (L f) = L (weave ctx hdl f)
  weave ctx hdl (R g) = R (weave ctx hdl g)

instance Syntax (Error e) where
  weave _ _ (Throw x) = Throw x
  weave ctx hdl (Catch p h k) =
    -- forall x. Catch (m x) (e -> m x) (x -> m a)
    Catch
      (hdl (fmap (const p) ctx))
      (\e -> hdl (fmap (const (h e)) ctx))
      (hdl . fmap k)
```

`const` is used solely to wrap our results in a way that `hdl` expects. With
these instances fully defined, we can now finish our `runError` handler:

```haskell
runError (Free (R other)) =
  Free $ weave (Right ()) (either (pure . Left) runError) other
```

### Lifting

The solution we've developed so far wouldn't be especially useful if it was
weaker than the previous. As mentioned before, our new solution splits the
functionality of `fmap` into extension and weaving. But nothing is stopping us
from defining an instance that continues using `fmap` for both. Consider the
following:

```haskell
newtype Lift sig (m :: Type -> Type) a = Lift (sig (m a))
```

Here `sig` refers to the lower-order data type we want to elevate to our
higher-order `Free`, e.g. `State s`:

```haskell
type HState s = Lift (State s)

hIncrement :: Free (Lift (State Int)) ()
hIncrement = Free (Lift (Get (\s -> Free (Lift (Put (s + 1) (Pure ()))))))

type HVoid = Lift Void

run :: Free HVoid a -> a
run (Pure a) = a
run _ = error (pack "impossible")
```

Here `hIncrement` is a lifted version of `increment` defined before. Likewise,
`run` remains nearly identical to its previous definition. Making `Lift` an
instance of `Syntax` is a equally straightforward:

```haskell
 instance Functor sig => HFunctor (Lift sig) where
   hmap t (Lift f) = Lift (fmap t f)

 instance Functor sig => Syntax (Lift sig) where
   emap t (Lift f) = Lift (fmap t f)

   weave ctx hdl (Lift f) = Lift (fmap (\p -> hdl (fmap (const p) ctx)) f)
```

The corresponding smart constructors and state handler should look like before,
but with our `ctx` now carrying the state around:

```haskell
get :: forall s sig. HFunctor sig => Member (HState s) sig => Free sig s
get = inject (Lift (Get Pure))

put :: forall s sig. HFunctor sig => Member (HState s) sig => s -> Free sig ()
put s = inject (Lift (Put s (pure ())))

runState ::
  forall s a sig.
  Syntax sig =>
  s ->
  Free (HState s :+: sig) a ->
  Free sig (s, a)
runState s (Pure a) = pure (s, a)
runState s (Free (L (Lift (Get f)))) = runState s (f s)
runState _ (Free (L (Lift (Put s f)))) = runState s f
runState s (Free (R other)) = Free (weave (s, ()) hdl other)
  where
    hdl :: forall x. (s, Free (HState s :+: sig) x) -> Free sig (s, x)
    hdl = uncurry runState
```

With all this in place, we can finally construct our `countDown` example again:

```haskell
countDown ::
  forall sig.
  Syntax sig =>
  Member (HState Int) sig =>
  Member (Error ()) sig =>
  Free sig ()
countDown = do
  decr {- 1 -}
  catch (decr {- 2 -} >> decr {- 3 -}) pure
  where
    decr = do
      x <- get @Int
      if x > 0 then put (x - 1) else throw ()
```

Now if we encounter an error within our `catch` statement, the local state
semantics are respected:

```haskell
>>> run . runError @() . runState @Int 2 $ countDown
Right (1,())
```

Pay attention to *why* this works - we first use our `runState` handler and
eventually encounter `decr {- 3 -}` which returns `throw ()` instead of
`put (x - 1)`. During this process, weave was invoked on a `Catch` with context
`(s, )` used to maintain the state at the time. Next `runError` is invoked which
sees the `Catch`, encounters the returned `Throw` after running the scoped
program, and invokes the error handler which has our saved state.

# Limitations

Though the higher-order free implementation is largely a useful tool for
managing effects, it is not perfect. I've had an especially hard time getting
resource-oriented effects working, e.g. with custom effects like so:

```haskell
data Server hdl conn (m :: * -> *) k where
  Start :: SpawnOptions -> Server hdl conn m hdl
  Stop :: hdl -> Server hdl conn m ExitCode
  GetPort :: hdl -> Server hdl conn m PortNumber
  Open :: Text -> PortNumber -> Server hdl conn m conn
  Close :: conn -> Server hdl conn m ()
```

The issue here being running the custom `Server` handler invokes `start` *and*
`stop` when wrapped in some [bracket](https://github.com/fused-effects/fused-effects-exceptions)-like
interface, even if the bracketed code has not yet finished. I have settled on
workarounds, but these workarounds consist of just structuring these kind of
effects differently.

In general, modeling asynchronous or `IO`-oriented operations feel "unsolved"
with solutions resorting to some [forklift](https://apfelmus.nfshost.com/blog/2012/06/07-forklift.html)
strategy or other ad-hoc solutions that don't feel as cemented in literature. I
don't necessarily think these are the *wrong* approach (I frankly don't know
enough to have a real opinion here), but it'd be nice to feel there was some
consensus as to what a non-hacky solution theoretically looks like.

Additionally, it is cumbersome remembering the order handlers should be applied
to achieve the desired global vs. local state semantics. This is not exclusively
a problem of free effect systems (e.g. MTL also suffers from this), but the
issue feels more prominent here.

# Conclusion

I will continue exploring effect systems à la free, but I am admittedly not
yet convinced they are the right way forward. Unfortunately, they can be hard to
reason about with unexpected interactions between effects if not careful. I am
sure a large contributing factor to this conclusion is the lack of
beginner-oriented documentation regarding proper use and edge cases. Just to
build up this post required reading source code of multiple effects libraries
and scattered blog posts, watching various YouTube videos, etc. And, despite all
that, I am still not confident I understand the implementation details behind
certain key abstractions. Hopefully this entry threads the needle between
exposition and overt jargon to get us a little closer though.

&nbsp;

---

[^1]: Though there exists a categorical definition of what makes something **free**, in this case it suffices to substitute "free" with "systematic".
