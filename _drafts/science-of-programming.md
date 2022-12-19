There exists certain short-comings. Consider the following implementation of counting sort:


COUNTING-SORT(A, B, k)
let C[0..k] be a new array
for i = 0 to k
  C[i] = 0
for j = 1 to A.length
  C[A[j]] = C[A[j]] + 1
// C[i] now contains the number of elements equal to i.
for i = 1 to k
  C[i] = C[i] + C[i - 1]
// C[i] now contains the number of elements less than or equal to i.
for j = A.length downto 1
  B[C[A[j]]] = A[j]
  C[A[j]] = C[A[j]] - 1


Now, how do we prove this sort is stable? Informally, we argue the following:

Let $1 \leq i_1 < j_1 \leq n$ such that $A[i_1] == A[j_1]$. Let $X_i$ and $X_j$ denote A[i_1] and A[j_1] respectively. Though X_i = X_j, we treat them as distinct entities. We then want to show that the value 1 \leq i_2 \leq n and $1 \leq j_2 \leq n$ such that $B[i_2] = X_i$ and $B[j_2] = X_j$ satisfies i_2 < j_2. This can be seen by the fact that our lats lines iterate backward. Because we iterate downward from $A$, we encounter X_j first. Since after positioning it in B, we decrement the count, then X_i's position in B must be less (since they share the same counter).

How do we prove this formally though? We could appeal to the prediate logic and predicate transformer calculus. Let $same(a, b)$ be the predicate denoting a and b have the same value, even if distinct entities. Then we have pre- and post-condition

P : 1 \leq i_1 < j_1 \leq n \land same(A[i_1], A[j_1]) \land A[i_1] = X_i \land A[j_1] = X_j
R : 1 \lqe i_2 < j_2 \leq n \land B[i_2] = X_i \land B[j_2] = X_j

That is, all we want to show is the earlier index has X_i in it. Now
\weakop(DO, R) = (\exists\,k : 0 \leq k : H_k(R)).
We know there exists some k for which the loop terminates; fix that k. Question is,
does it terminate with our postcondition set?

H_k(R)
  = H_0(R) \lor \weakop(IF, H_{k-1}(R))
  = (j = 0 \land R) \lor \weakop(



\weakop(IF, R)
  = j \neq 0 \land (\forall\,i : 1 \leq i \leq n : B_i \Rightarrow \weakop(S_i, R))
  = j \neq 0 \land (j \neq 0 \Rightarrow ("B[C[A[j]]] := A[j]; C[A[j]] := C[A[j]] - 1", R))
  = j \neq 0 \land (j \neq 0 \Rightarrow ("B[C[A[j]]] := A[j]" \weakop("C[A[j]] := C[A[j]] - 1", R))
  = j \neq 0 \land (j \neq 0 \Rightarrow ("B[C[A[j]]] := A[j]", R_{C[A[j]] - 1}^{C[A[j]]} \\
  = j \neq 0 \land (j \neq 0 \Rightarrow ("B[C[A[j]]] := A[j]", R_{(C; A[j]{:}C[A[j]] - 1)}^{C}

