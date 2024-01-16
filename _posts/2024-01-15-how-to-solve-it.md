---
title: How to Solve It
tags: [proof, math, problem solving]
categories: home
math: true
---

Much of my focus over the past year or two has been oriented around learning how
to learn and systematizing how I go about thinking and solving problems. To this
end I've created thousands of [Anki flashcards](https://ankiweb.net/about),
tried various [Zettelkasten](https://zettelkasten.de/) systems, and began
reading many books on the subject. The purpose of this post is to discuss one of
these books.

George Pólya's *How to Solve It* is a very well-known text on how to
methodically approach a problem. I've transcribed the practice problems Pólya
lists at the end of his book and try to solve them in two ways. The first listed
solution will recount my "default" approach. Here I'll write out my thoughts as
I have them, detailing my thought process, points where I feel stuck or unsure,
and eventually the answer I commit to (to be highlighted in **bold**). Once I
finish going through all the problems, I'll run through them each again but with
Pólya's framework equipped. The hope here is to more systematically break down
the problem and contrast the strategy against those I use in my initial
attempts.

After my second pass, I'll perform a final pass in which I transcribe the
answers found in the back of the book and discuss my overall thoughts on the
problem.

{% include inline-toc.html %}

## Problems

### Question 1

A bear, starting from the point $P$, walked one mile due south. Then he changed
direction and walked one mile due east. Then he turned again to the left and
walked one mile due north, and arrived exactly at the point $P$ he started from.
What was the color of the bear?

{% accordion First Pass %}
After reading this question, my mind immediately goes to what possible colors
a bear can take on. I think "brown", "black", and "white". A distinguishing
feature of the different colored bears is geography, so, considering the
question discusses cardinal directions, this seems like the correct line of
thinking. For a bear to walk in these three directions and end up in the same
location means there must be a "bend" on the plane the bear is walking in. I
picture this:

![question1](/assets/img/how-to-solve-it/question1.jpg)

Since this path would only be possible at Earth's poles, the bear must be
**white**.
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 2

Bob wants a piece of land, exactly level, which has four boundary lines. Two
boundary lines run exactly north-south, the two others exactly east-west, and
each boundary line measures exactly $100$ feet. Can Bob buy such a piece of
land in the U.S.?

{% accordion First Pass %}
There are a couple of constraints that are defined in the problem description:

* The plot of land must be $100 \text{ ft}^2$.
* The plot of land must be exactly level.
* The plot of land must exist within the U.S.

Finding a plot of land this large that is exactly level feels impossible. My
immediate reaction is that the answer to this question is "no" because of this
condition alone.

---

Taking a step back though, I'm making a few assumptions that took me a while to
realize I was making. Let's revisit the conditions again, but more at face
value.

One, the piece of land must be in the U.S. What does this condition enforce?
Well, it does at least limit the sort of geometrical shenangians
[question 1](#question-1) took advantage of. If constrained to within the U.S.,
a region having north-south and east-west boundary lines should form a shape
closer to a square than an equivalently-defined shape closer to either of
Earth's poles. That doesn't necessarily mean these boundary lines do form a
square though - it's wrong to assume we're looking for a $100 \text{ ft}^2$ plot
of land.

Two, this piece of land should be exactly level. I didn't realize it at first,
but I had implicitly added the constraint that this piece of land must be
naturally occurring. If we had a plot of land satisfying the other two
conditions, we could make the plot level prior to sale, allowing us to answer
our question in the affirmative.

The question now becomes whether or not we can form a closed shape in which two
boundary lines are exactly north-south, two boundary lines are exactly
east-west, and all four line measure $100\text{ ft}$. A diagram in this case
helps:

![question2](/assets/img/how-to-solve-it/question2.jpg)

What this diagram makes clear is that closed regions in the northern hemisphere
bounded by lines running exactly north-south and east-west have a shorter
top-edge (i.e. the edge closer to the north pole) than bottom-edge (i.e. the
edge closer to the equator). Though the scale of the diagram is much larger than
our problem entails, the principle remains the same. The answer remains **no**,
though for reasons different than that of my initial reaction.
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 3

Bob has $10$ pockets and $44$ silver dollars. He wants to put his dollars into
his pockets so distributed that each pocket contains a different number of
dollars. Can he do so?

{% accordion First Pass %}
Arbitrarily name the pockets $0, 1, \ldots, 9$ and denote the number of dollars
in the $i^{\text{th}}$ pocket as $P_i$. There are two conditions to satisfy:

1. $\sum_{i=0}^9 P_i = 44$.
1. For all distinct integers $0 \leq i, j \leq 9$, $P_i \neq P_j$.

To get a feel for the problem, let's see what happens if $P_i = i$ for
$0 \leq i \leq 9$. In this scenario, condition 2 is trivially met. The number of
dollars across the pockets would be $$0 + 1 + 2 + \cdots + 9 = 45.$$ By chance
we likely discovered why the question chooses the number $44$ - it's value is
one less than the total produced by taking this approach.

In fact, this series consist of the smallest possible summands we can use that
still "fits" the problem statement. Any other set of dollar amounts would
produce a larger total. Therefore the answer must be **no**, Bob cannot
distribute the dollars in his pockets so that each contains a different number
of dollars.
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 4

To number the pages of a bulky volume, the printer used $2989$ digits. How many
pages has the volume?

{% accordion First Pass %}
We first establish a lower bound. To do so, construct a table where each row
keeps a running count of the total number of pages encountered so far.

Radix   | Count                    | Cumulative
------- | ------------------------ | ------------------
$1$     | $9 - 1 + 1 = 9$          | $1 \times 9 = 9$
$2$     | $99 - 10 + 1 = 90$       | $9 + 2 \times 90 = 189$
$3$     | $999 - 100 + 1 = 900$    | $189 + 3 \times 900 = 2889$

This means between pages $1$ to $999$ inclusive, we've used $2889$ digits to
number our pages. Now we're only $100$ digits away from our goal. Since all
subsequent pages consist of four digits, our final answer must be

$$100 / 4 + 999 = \textbf{1024 pages}.$$
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 5

Among Grandfather's papers a bill was found:

$$72 \text{ turkeys } \$\_67.9\_$$

The first and last digit of the number that obviously represented the total
price of those fowls are replaced here by blanks, for they have faded and are
now illegible.

What are the two faded digits and what was the price of one turkey?

{% accordion First Pass %}
As a starting point, the first digit must be a number between $1$ and $9$
inclusive. Similarly, the last number is between $0$ and $9$ inclusive. Assuming
the real total is $N$, then we expect $N / 72$ to evaluate to a number with at
most two decimal places. We also must somehow be convinced that the pair of
numbers we find satisfying the problem statement is the *only* pair that could
satisfy the problem statement.

Let's try playing around with some digits to get a feel for the problem.
Consider $N = \\$167.90$. Then $N / 72 \approx \\$2.332$ meaning we chose $N$
wrong. Consider another pair of digits, say $N = \\$767.92$. Here
$N / 72 \approx \\$10.666$. It's clear that picking and choosing values is not
a great strategy. That said, it's not immediately obvious to me how to go about
moving forward. A few thoughts I have:

1. Why is the number $72$ used here?
1. Are there certain "cent" values that only show up w.r.t. $72$?
1. Is actually enumerating all $90$ possible pairs of digits a viable option?
1. Can we define bounds on what the price of an individual turkey is?
1. Can we reduce our search space down a bit?

With (1), nothing immediately comes to mind as particularly interesting about
$72$. Its factorization is something I'm considering, but how that helps isn't
obvious. (2) relates to (5) so we'll return to this point later. (3) feels
antithetical to the problem so I'm going to dismiss it.

These last two questions feel like they might have legs though. Even if neither
lead to a definitive answer, perhaps they'll provide insights into how to
navigate the problem better. So, first off, can we define bounds on the price
$P$ of an individual turkey? The smallest candidate for the total price is
$\\$167.90$ whereas the largest candidate is $\\$967.99$. Therefore

$$\\$2.332 \approx \\$167.90 / 72 \leq P \leq \\$967.99 / 72 \approx \\$13.444$$

Next let's consider how we can reduce our search space. One optimization is that
the last digit must be even (since $72$ is even). This reduces the possible
number of pairs to check down to $45$. Now we revisit (2) - instead of looking
at just one digit, can we look at the last two? Which of $90$, $92$, $94$, $96$,
and $98$ could serve as a solution to $P \times 72 \bmod 100 \equiv x$?

---

Here I feel a bit discouraged. It feels like the approaches I'm taking are more
complicated that the problem should warrant and I'm not feeling like I've found
a "groove" to latch onto. For now, I'm going to take this as my first real
problem to try applying Pólya's framework to.
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 6

Given a regular hexagon and a point in its plane. Draw a straight line through
the given point that divides the given hexagon into two parts of equal area.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 7

Given a square. Find the locus of the points from which the square is seen under
an angle (a) of $90^\circ$ (b) of $45^\circ$. (Let $P$ be a point outside the
square, but in the same plane. The smallest angle with vertex $P$ containing
the square is the "angle under which the square is seen" from $P$.) Sketch
clearly both loci and give a full description.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 8

Call "axis" of a solid a straight line joining two ponits of the surface of the
solid and such that the solid, rotated about this line through an angle which is
greater than $0^\circ$ and less than $360^\circ$ coincides with itself.

Find the axes of a cube. Describe clearly the location of the axes, find the
angle of rotation associated with each. Assuming that the edge of the cube is of
unit length, compute the arithmetic mean of the lengths of the axes.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 9

In a tetrahedron (which is not necessarily regular) two opposite edges have the
same length $a$ and they are perpendicular to each other. Moreover they are each
perpendicular to a line of length $b$ which joins their midpoints. Express the
volume of the tetrahedron in terms of $a$ and $b$, and prove your answer.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 10

The vertex of a pyramid opposite the base is called the *apex*. (a) Let us call
a pyramid "isosceles" if its apex is at the same distance from all vertices of
the base. Adopting this definition, prove that the base of an isosceles pyramid
is *inscribed* in a circle the center of which is the foot the pyramid's
altitude.

(b) Now let us call a pyramid "isosceles" if its apex is at the same
(perpendicular) distance from all sides of the base. Adopting this definition
(different from the foregoing) prove that the base of an isosceles pyramid is
*circumscribed* about a circle the center of which is the foot of the pyramid's
altitude.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 11

Find $x$, $y$, $u$, and $v$, satisfying the system of four equations

$$\begin{align*}
    x + 7y + 3v + 5u &= 16 \\
    8x + 4y + 6v + 2u &= -16 \\
    2x + 6y + 4v + 8u &= 16 \\
    5x + 3y + 7v + u &= -16 \\
\end{align*}$$

(This may look long and boring: look for a short cut.)

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 12

Bob, Peter, and Paul travel together. Peter and Paul are good hikers; each walk
$p$ miles per hour. Bob has a bad foot and drives a small car in which two
people can ride, but not three; the car covers $c$ miles per hour. The three
friends adopted the following scheme: They start together, Paul rides in the car
with Bob, Peter walks. After a while, Bob drops Paul, who walks on; Bob returns
to pick up Peter, and then Bob and Peter ride in the car till they overtake
Paul. At this point they change: Paul rides and Peter walks just as they started
and the whole procedure is repeated as often as necessary.

(a) How much progress (how many miles) does the company make per hour?

(b) Through which fraction of the travel time does the car carry just one man?

(c) Check the extreme cases $p = 0$ and $p = c$.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 13

Three numbers are in arithmetic progression, three other numbers in geometric
progression. Adding the corresponding terms of these two progressions
successively, we obtain $$85, 76, \text{ and } 84$$ respectively, and, adding
all three terms of the arithmetic progression, we obtain $126$. Find the terms
of both progressions.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 14

Determine $m$ so that the equation in $x$

$$x^4 - (3m + 2)x^2 + m^2 = 0$$

has four real roots in arithmetic progression.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 15

The length of the perimeter of a right triangle is $60$ inches and the length
of the altitude perpendicular to the hypotenuse is $12$ inches. Find the sides.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 16

From the peak of a mountain you see two points, $A$ and $B$, in the plain. The
lines of vision, directed to these points, include the angle $\gamma$. The
inclination of the first line of vision to a horizontal plane is $\alpha$, that
of the second line $\beta$. It is known that the points $A$ and $B$ are on the
same level and that thte distance between them is $c$.

Express the elevation $x$ of the peak above the common level of $A$ and $B$ in
terms of the angles $\alpha$, $\beta$, $\gamma$, and the distance $c$.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 17

Observe that the value of

$$\frac{1}{2!} + \frac{2}{3!} + \frac{3}{4!} + \cdots + \frac{n}{(n + 1)!}$$

is $\frac{1}{2}$, $\frac{5}{6}$, $\frac{23}{24}$ for $n = 1, 2, 3$,
respectively, guess the general law (by observing more values if necessary) and
prove you guess.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 18

Consider the table

$$\begin{align*}
1 & = 1 \\
3 + 5 & = 8 \\
7 + 9 + 11 & = 27 \\
13 + 15 + 17 + 19 & = 64 \\
21 + 23 + 25 + 27 + 29 &= 125
\end{align*}$$

Guess the general law suggested by these examples, express it in suitable
mathematical notation, and prove it.

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 19

The side of a regular hexagon is of length $n$ ($n$ is an integer). By
equidistance parallels to its sides the hexagon is divided into $T$ equilateral
triangles each of which has sides of length $1$. Let $V$ denote the number of
vertices appearing in this division, and $L$ the number of boundary lines of
length $1$. (A boundary line belongs to one or two triangles, a vertex to two or
more triangles.) When $n = 1$, which is the simplest case, $T = 6$, $V = 7$,
$L = 12$. Consider the general case and express $T$, $V$, and $L$ in terms of
$n$. (Guessing is good, proving is better.)

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

### Question 20

In how many ways can you change one dollar? (The "way of changing" is determined
if it is known how many coins of each kind - cents, nickels, dimes, quarters,
half dollars - are used.)

{% accordion First Pass %}
_
{% endaccordion %}

{% accordion Second Pass %}
_
{% endaccordion %}

{% accordion Final Pass %}
_
{% endaccordion %}

## Conclusion

TODO
