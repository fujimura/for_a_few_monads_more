第14章 もうちょっとだけモナド
===

第7回 スタートHaskell2 (最終回) まだまだモナド (Reader, Writer, State, Error, ...) 発表資料

藤村大介 ([@ffu_](http://twitter.com/ffu_) / [http://fujimuradaisuke.com/](http://fujimuradaisuke.com/))

自己紹介
===

藤村大介 ([@ffu_](http://twitter.com/ffu_) / [http://fujimuradaisuke.com/](http://fujimuradaisuke.com/))

フリーランスのプログラマー。

仕事では主にRubyを書いている。

Haskell歴は一年強くらい。下記のようにWebアプリケーション、テストの周辺に興味があります。

* [HspecでWAIアプリケーションのテストをする話をひと月前に書きました](http://blog.fujimuradaisuke.com/post/40413685410/hspec-wai)

* [HaskellでJSON Web APIを作ると幸せになれるかもよ](http://blog.fujimuradaisuke.com/post/26887032662/haskell-de-json-web-api)

このスライドについて
===

Literate Haskell + Markdownで書いて、pandocでスライドを生成しています。

```shell
pandoc -t slidy -s for_a_few_monads_more.lhs -o for_a_few_monads_more.html
```

するとスライドができます。

```shell
ghci for_a_few_monads_more.lhs
```

するとこのファイルで定義した関数が試せます。

ということで、ちょっとモジュールをインポートしますね…。

> {-# LANGUAGE FlexibleContexts  #-}
> import Data.Monoid
> import Control.Monad.Writer
> import Control.Monad.State
> import Control.Monad.Instances
> import System.Random

Writer
===


ギャングの人数
===

> isBigGang' :: Int -> Bool
> isBigGang' x = x > 9

    *Main> isBigGang' 19
    True


ギャングの人数+何をしたか
===

> isBigGang :: Int -> (Bool, String)
> isBigGang x = (x > 9, "Compared gang size to 9")

    *Main> isBigGang 19
    (True,"Compared gang size to 9")

---

「何をしたか」という文脈を保ったまま、さらに人数をチェック
===

> applyLog' :: (a, String) ->        -- 文脈付きの値
>              (a -> (b, String)) -> -- 値をとって、文脈付きの別の値を返す
>              (b, String)           -- 文脈付きの値
> applyLog' (x, log) f = let (y, newLog) = f x in (y, log ++ newLog)

    *Main> (3, "Smallish gang.") `applyLog'` isBigGang
    (False,"Smallish gang.Compared gang size to 9")
    *Main> (30, "A freaking platoon.") `applyLog'` isBigGang
    (True,"A freaking platoon.Compared gang size to 9")

「何をしたか」＝ログ をリストやByteStringで記録したい
===

> applyLog :: (Monoid m) =>         -- モノイド値、リストとかByteStringとか
>             (a, m) ->             -- モノイド値付きの値
>             (a -> (b, m)) ->      -- 値をとって、モノイド値付きの別の値を返す
>             (b, m)                -- モノイド値付きの値
> applyLog (x, log) f = let (y, newLog) = f x in (y, log `mappend` newLog)

タプルは「値と、モノイド値のおまけ」になりました。

セットの飲み物を追加する関数
===

おまけ付き型を使って、`addDrink`で食べ物にセットの飲み物をつけつつ小計を計算します。

> -- import Data.Monoid
>
> type Food = String
> type Price = Sum Int
>
> addDrink :: Food -> (Food, Price)
> addDrink "beans" = ("milk", Sum 25)
> addDrink "jerky" = ("whiskey", Sum 99)
> addDrink _       = ("beer", Sum 30)

なんと食べ物につく飲み物の種類は選べません

    ghci> ("beans",  Sum 10) `applyLog` addDrink
    ("milk", Sum {getSum = 35})
    ghci> ("jerky",  Sum 25) `applyLog` addDrink
    ("whiskey", Sum {getSum = 124})
    ghci> (("jerky", Sum 10) `applyLog` addDrink ) `applyLog` addDrink
    ("beer", Sum {getSum = 139})

ジャーキー + ウイスキー + ビール。飲む順番が逆のような…

おまけ付き = Writer型だった
===

おまけ付きを一般化したものがWriterです。

[Control.Monad.Writer](http://hackage.haskell.org/packages/archive/mtl/latest/doc/html/Control-Monad-Writer-Class.html)がWriter w aって型、そのMonadインスタンス、便利関数を提供しています。

```haskell
newtype Writer w a = Writer { runWriter :: (a, w) }
```

```haskell
instance (Monoid w) => Monad (Writer w) where
    return x = Writer (x, mempty)
    (Writer (x, v)) >>= f = let (Writer (y, v')) = f x
                              in Writer (y, v `mappend` v')
```


`>>=`は`applyLog`そっくりですね。`applyLog`でタプルを返していたところを`Writer`にしました。

`return`は空のモノイド値で`Writer`を作って返しています。

用例です。

    ghci> runWriter (return 3 :: Writer String Int)
    (3, "")
    ghci> runWriter (return 3 :: Writer (Sum Int) Int)
    (3, Sum {getSum = 0})
    ghci> runWriter (return 3 :: Writer (Product Int) Int)
    (3, Product {getProduct = 1})

Writerをdo記法で使う
===

> -- import Control.Monad.Writer
>
> logNumber :: Int -> Writer [String] Int
> logNumber x = writer (x, ["Got number: " ++ show x])
>
> multWithLog :: Writer [String] Int
> multWithLog = do
>     a <- logNumber 3
>     b <- logNumber 5
>     tell ["Gonna multiply these two"]
>     return (a*b)

    ghci> runWriter multWithLog
    (15,["Got number: 3","Got number: 5","Gonna multiply these two"])

(余談) Writerをモナド内包表記で使う
===

`{-# LANGUAGE MonadComprehensions #-}`すれば、`do`の部分をリスト内包表記のような記法で書けます。

詳しくはこちら
[Monad comprehensions](http://hackage.haskell.org/trac/ghc/wiki/MonadComprehensions)

```haskell
logNumber x :: Int -> Writer [String] Int
logNumber x = writer (x, ["Got number: " ++ show x])
```

    ✈ ghci for_a_few_monads_more.lhs -XMonadComprehensions
    ghci> runWriter [a * b | a <- logNumber 3, b <- logNumber 2]
    (6,["Got number: 3","Got number: 2"])

かっこいいです！

Writerを使ったログ付きユークリッド互除法
===

省略

差分リスト
===

リストの結合
===

```haskell
(++) :: [a] -> [a] -> [a]
(++) []     ys = ys
(++) (x:xs) ys = x : xs ++ ys
```

右結合
===

```haskell
[1,2,3] ++ ([4,5,6] ++ [7,8,9])

[1,2,3] ++ (4:[5,6] ++ [7,8,9])
[1,2,3] ++ (4:5:[6] ++ [7,8,9])
[1,2,3] ++ (4:5:6:[] ++ [7,8,9])
[1,2,3] ++ [4,5,6,7,8,9]
1:[2,3] ++ [4,5,6,7,8,9]
1:2:[3] ++ [4,5,6,7,8,9]
1:2:3:[] ++ [4,5,6,7,8,9] -- 7回

[1,2,3,4,5,6,7,8,9]
```

8回でできました。

左結合
===

```haskell
([1,2,3] ++ [4,5,6]) ++ [7,8,9]

(1:[2,3] ++ [4,5,6]) ++ [7,8,9]
(1:2:[3] ++ [4,5,6]) ++ [7,8,9]
(1:2:3:[] ++ [4,5,6]) ++ [7,8,9]
[1,2,3,4,5,6] ++ [7,8,9]
1:[2,3,4,5,6] ++ [7,8,9] -- ここはさっきやった
1:2:[3,4,5,6] ++ [7,8,9] -- ここはさっきやった
1:2:3:[4,5,6] ++ [7,8,9] -- ここはさっきやった
1:2:3:4:[5,6] ++ [7,8,9]
1:2:3:4:5:[6] ++ [7,8,9]
1:2:3:4:5:6:[] ++ [7,8,9] -- 10回

[1,2,3,4,5,6,7,8,9]
```

10回かかりました。一つ目のリストを二度構築しています。

リストを左結合で++すると時間がかかる
===

(++)は右結合なので、基本的には問題ないです。

    ghci> :i (++)
    (++) :: [a] -> [a] -> [a]       -- Defined in `GHC.Base'
    infixr 5 ++

しかし成り行き上

`((((a ++ b) ++ c) ++ d) ++ e) ++ f`

のような左結合の式になってしまうこともあるでしょう。


差分リストを使おう
===

> newtype DiffList a = DiffList { getDiffList :: [a] -> [a] }
>
> toDiffList :: [a] -> DiffList a
> toDiffList xs = DiffList (xs ++)
>
> fromDiffList :: DiffList a -> [a]
> fromDiffList (DiffList f) = f []
>
> instance Monoid (DiffList a) where
>     mempty = DiffList (\xs -> [] ++ xs)
>     (DiffList f) `mappend` (DiffList g) = DiffList (\xs -> f (g xs))

最後の`(\xs -> f (g xs))` が重要です。

```haskell
toDiffList [1,2,3] `mappend` toDiffList [4,5,6]
= \xs -> ([1,2,3] ++) (([4,5,6] ++) xs)
```

これを`fromDiffList`すると

```haskell
([1,2,3] ++) (([4,5,6] ++) [])
[1,2,3] ++ ([4,5,6] ++ [])
```

右結合になります！

(->) r, aka Reader
===

関数はモナドだった
===

定義

```haskell
instance Monad ((->) r) where
    return x = \_ -> x
    h >>= f = \w -> f (h w) w
```

`h`は`(m a)`、つまり関数です。`w`を渡すと、結果を返します。関数なので当たり前ですね。

`f`は`(a -> m b)`。ここでは`(h w)`の計算結果を`a`にバインドして、関数`(m b)`を`w`で実行しようとします。


使ってみます

> addStuff :: Int -> Int
> addStuff = do
>     a <- (* 2)
>     b <- (+ 10)
>     return (a + b)

    ghci> addStuff 100
    310


`h >>= f = \w -> f (h w) w`とは…？
===


`>>=`の定義が複雑だと思いました。

下記の1を足す関数で調べてみましょう。

```haskell
addOne :: Int -> Int
addOne = do
   a <- (+ 1)
   return a
```

まずはdoを剥がします。

```haskell
addOne :: Int -> Int
addOne = (+ 1) >>= \a -> return a
```

右辺を簡約すると、本当に関数になりました！

```haskell
(+ 1) >>= (\a -> return a )
    \w -> (\a -> return a ) ((+ 1) w) w -- `h >>= f = \w -> f (h w) w`
    \w -> (\a -> (\_ -> a)) ((+ 1) w) w -- `return x` = `\_ -> x`
    \w -> const             ((+ 1) w) w -- `\a -> \_ -> a` = `const`
    \w ->                    (+ 1) w    -- `const`を適用
                             (+ 1)      --  remove eta reduction
```


State
===

定義
===

```haskell
newtype State s a = State { runState :: s -> (a, s) }

instance Monad (State s) where
    return x = State $ \s -> (x, s)
    (State h) >>= f = State $ \s ->
        let (a, newState) = h s -- 状態付き計算を現在の状態で実行、新しい値aと新しい状態newStateを入手
            (State g) = f a     -- 渡された関数にaを適用、次の状態付き計算gを手に入れる
        in g newState           -- 次の状態付き計算gを新しい状態newStateで実行
```

スタックをStateモナドで
===

> -- import Control.Monad.State
> type Stack = [Int]
>
> pop :: State Stack Int
> pop = state $ \(x:xs) -> (x, xs)
>
> push :: Int -> State Stack ()
> push a = state $ \xs -> ((), a:xs)
>
> stackStuff :: State Stack ()
> stackStuff = do
>     a <- pop
>     if a == 5
>         then push 5
>         else do
>             push 3
>             push 8

    ghci> runState stackStuff [9,0,2,1,0]
    ((),[8,3,0,2,1,0])


乱数生成器をStateモナドで
===

これが

```haskell
threeCoins :: StdGen -> (Bool, Bool, Bool)
threeCoins gen =
    let (firstCoin, newGen) = random gen
        (secondCoin, newGen') = random newGen
        (thirdCoin, newGen'') = random newGen'
    in  (firstCoin, secondCoin, thirdCoin)
```

こう書けます。

> randomSt :: (RandomGen g, Random a) => State g a
> randomSt = state random
>
> threeCoins :: State StdGen (Bool, Bool, Bool)
> threeCoins = do
>     a <- randomSt
>     b <- randomSt
>     c <- randomSt
>     return (a, b, c)

初期状態を渡してあげると、三枚のコインをトスします。

    ghci> runState threeCoins (mkStdGen 33)
    ((True,False,True),680029187 2103410263)

Errorを壁に
===

定義

```haskell
instance (Error e) => Monad (Either e) where
    return x = Right x
    Right x  >>= f = f x
    Left err >>= f = Left err
    fail msg = Left (strMsg msg)
```

Nothingに文脈がついたMaybeと考えればよいでしょう。

    ghci> Left "boom" >>= \x -> return (x+1)
    Left "boom"
    ghci> Right 100 >>= \x -> Left "no way!"
    Left "no way!"
    ghci> Right 3 >>= \x -> return (x + 100)
    <interactive>:1:0:
        Ambiguous type variable `a' in the constraints:
          `Error a' arising from a use of `it' at <interactive>:1:0-33
          `Show a' arising from a use of `print' at <interactive>:1:0-33
        Probable fix: add a type signature that fixes these type variable(s)
    ghci> -- Either e aの型シグネチャを付ける必要がある
    ghci> Right 3 >>= \x -> return (x + 100) :: Either String Int
    Right 103


モナディック関数
===

liftM
===

```haskell
liftM :: (Monad m) => (a -> b) -> m a -> m b
liftM f m = do
    x <- m
    return (f x)
````

fmapと同じです。

    ghci> liftM (*3) (Just 8)
    Just 24
    ghci> fmap (*3) (Just 8)
    Just 24
    ghci> runWriter $ liftM not $ Writer (True,  "chickpeas")
    (False, "chickpeas")
    ghci> runWriter $ fmap not $ Writer (True,  "chickpeas")
    (False, "chickpeas")
    ghci> runState (liftM (+100) pop) [1, 2, 3, 4]
    (101, [2, 3, 4])
    ghci> runState (fmap (+100) pop) [1, 2, 3, 4]
    (101, [2, 3, 4])

歴史的な経緯でMonadはFunctorではないので、liftMが用意されているようです。

ap
===

```haskell
ap :: (Monad m) => m (a -> b) -> m a -> m b
ap mf m = do
    f <- mf
    x <- m
    return (f x)
```

`<*>`と同じです。

    ghci> Just (+3) <*> Just 4
    Just 7
    ghci> Just (+3) `ap` Just 4
    Just 7
    ghci> [(+1), (+2), (+3)] <*> [10, 11]
    [11, 12, 12, 13, 13, 14]
    ghci> [(+1), (+2), (+3)] `ap` [10, 11]
    [11, 12, 12, 13, 13, 14]


歴史的な経緯でMonadはApplicativeではないので、liftMが用意されているようです。

join
===

ネストしたモナドをまとめてくれます。

```haskell
join :: (Monad m) => m (m a) -> m a
join mm = do
    m <- mm
    m
```

    ghci> join (Just (Just 9))
    Just 9
    ghci> join (Just Nothing)
    Nothing
    ghci> join Nothing
    Nothing

    ghci> join [[1, 2, 3], [4, 5, 6]]
    [1, 2, 3, 4, 5, 6]

    ghci> runWriter $ join (Writer (Writer (1, "aaa"), "bbb"))
    (1, "bbbaaa")

（個人的にはネストしたMaybeをまとめるのによく使います）


filterM, foldM
===

ご想像の通りです。

RPN
===

(時間切れ)

確率モナドを作ろう
===

(時間切れ)
