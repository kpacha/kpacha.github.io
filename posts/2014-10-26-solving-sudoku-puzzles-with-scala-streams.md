---
layout: post
title:  Solving sudoku puzzles with scala streams
tags:
    - scala
    - streams
    - sudoku
---

Scala has a very nice lazy evaluation system, allowing you to defer a lot of evaluations to the last moment. This is a nice to have feature when you are dealing with 'almost-infinite' lists. There are some examples on the web but I wanted bigger trees to explore in order to see it working, so I went to sudoku.

Board basics
----

Before going any further on the solving algorithm, we need to define some values and types

	type Position = (Int, Int)				// the type to handle pairs of coordinates
	val EmptyValue = '0'					// the char representing the empty cells
	val MaxValue = 9						// the number of columns and rows

	val allValues = "123456789".toList		// the list of all possible values of a cell
	val indexes = (0 to 8).toList			// the list of column and row indexes

Now we can go with the `Board` class. This will be responsible for parsing the game and generate a list of the next possible 'movements'. First of all, let's look at the object initialization phase

	class Board(val game: String) {
	    val empty = game indexOf EmptyValue
	    val emptyPosition = (empty % MaxValue, empty / MaxValue)
	    val isDone = empty == -1

	    ...
	}

Here we see that Board has a constructor param called `game`. On the object instantiation, it calculates the first empty position in the board. It also checks if the board is completed (when there are no more empty cells, we can assume the game is done).

Encapsulating the base info in a string allows us to manipulate it easily. It also allows us to override the `toString` method so the board will be displayed in a more human friendly way.

	override def toString: String = "\n" + (game sliding (MaxValue, MaxValue) mkString "\n")

Since our `Board` is based on a string definition of the game, we can add a function to create a new updated object with the same signature the `String` class exposes, so updating the `Board` will be as intuitive as updating the string that defines the object itself.

	def updated(pos: Int, value: Char): Board = new Board(game updated (pos, value))

The `Board` class must include some accessors to the cells it contains, so we must implement some getters by row, column and box (here, I'm calling each 3x3 block a box).

	def row(y: Int): List[Char] = indexes map (col => game(y * MaxValue + col))
    def col(x: Int): List[Char] = indexes map (row => game(x + row * MaxValue))
    def box(pos: Position): List[Char] = {
      def base(p: Int): Int = (p / 3) * 3
 
      val x0 = base(pos._1)
      val y0 = base(pos._2)
      val ys = (y0 until y0 + 3).toList
      (x0 until x0 + 3).toList.flatMap(x => ys.map(y => game(x + y * MaxValue)))
    }

As you can see, in order to get the values of a row or a column we just map the indexes `[0,8]` with the corresponding values of the game. Getting the box values is more complex because the boundaries of the box must be calculated before extracting the values of the game.

Next candidates
----

The easiest way to get a list of all possible values of a cell is to join all the values already placed in the same row, column and box. So we need a function to calculate the values a cell should not contain

	def toAvoid(pos: Position): List[Char] = (col(pos._1) ++ row(pos._2) ++ box(pos)).distinct

and then, get the values not included in the `toAvoid` list

	def candidates(pos: Position): List[Char] = allValues diff toAvoid(pos)

It is interesting to note that if there is not a single candidate, it will return an empty list.

The main objectives of the `Board` class was to encapsulate the game info and generate a list of the next possible movements. The first part is done. Let's finish the other one with the `next` function. Here we want to create a new `Board` for each candidate it found but we want to defer they evaluation until the last moment. So, now is when [streams](http://www.scala-lang.org/api/2.11.2/index.html#scala.collection.immutable.Stream) come to the rescue. A `Stream` defers the evaluation of the second param until it is required. By returning a `Stream[Board]` we avoid to instantiate every possible candidate until the code needs the next one to check if the game is finished or to ask for the next candidates.

	def next: Stream[Board] = candidates(emptyPosition).toStream map (c => updated(empty, c))

When it returns an empty `Stream`, you are done or you have some cell(s) wrong. Anyway, that is the way you know the path is finished.

At this moment, we are done with our `Board` class. Hurray!

The solver
----

Our `Sudoku` solver has to expose a board builder that instantiates our initial `Board`. Very straightforward task.

	def build(game: String): Board = new Board(game)

Time to create an almost infinite list of possible boards. We want to explore the tree efficiently, so we will use a breadth-first traversal algorithm. First, we emit the head, then we add its subnodes to the end of the list of nodes to explore and move to the next node of the level. When all the nodes in a level are checked, we move to the next one by inspecting the children of the first node of the already completed level.

Note we need to accept a list of boards in order to make the function recursive. This function will get the `head` of the `Stream` and then it will create a new `Stream` with that item and the result of the recursive call. The `Stream` passed to that recursive call is just the concatenation of the `tail` of the original `Stream` and the candidates returned by the `head`. Once the `tail` and the next candidates are empty, the path is finished.

	def from(path: Stream[Board]): Stream[Board] = path match {
		case h #:: t => h #:: from(t ++ h.next)
		case _ => Stream.empty
	}

Due the way our `Board` class generates the candidate `Stream`, we can assume our list will contain just valid boards, mostly incomplete.

Now we have a builder and a candidate generator, we can put it together and generate a `Stream` of valid boards starting from the received game definition string.

	def steps(game: String): Stream[Board] = from(Stream(build(game)))

The last function we must implement is the one that filters the `Stream` looking for a solved board. That is why we created the `isDone` val.

	def solve(game: String): Board = steps(game).filter(_.isDone).head

And we are done! Our solver will just evaluate the minimun steps required to get the first solved board.

Further optimizations
----

In order to avoid some repetitive calculations, it is possible to create a map with the positions a box contains out of the `Board` class and change the `box` function to get it filtering the game values with the precalculated map.

	val boxCoordinates = (0 to 2).toList

	def box(pos: Int): List[Int] = {
		def base(p: Int): Int = (p / 3) * 3

		val x0 = base(getX(pos))
		val y0 = base(getY(pos))
		val ys = (y0 until y0 + 3).toList
		(x0 until x0 + 3).toList.flatMap(x => ys.map(x + _ * 9))
	}

	val boxes = boxCoordinates flatMap (x => boxCoordinates map (x * 3 + _ * 3 * 9)) map box

	class Board(val game: String) {
    	...
    	def box(pos: Int): List[Char] = (boxes filter (_ contains pos)).head map game
    	...
    }

The complete code is availbe as a [gist](https://gist.github.com/kpacha/adeda0bd7a08076d67d0);