# Math

Inline sampler: **bold math text**, _italic math text_, `latex`, [math link](https://example.com/math), citation[^math-sample], and math $x^2$.

## Inline expressions

Inline math should render when complete: $E = mc^2$. A longer paragraph with a second expression, $a^2 + b^2 = c^2$, lets the inline renderer settle while prose continues to stream.

## Integral

Block math should remain readable while streaming and render once complete:

$$
\int_0^1 x^2 dx = \frac{1}{3}
$$

## Summation

Another block gives the demo a longer math-heavy stream:

$$
\sum_{i=0}^{n} i^2 = \frac{n(n+1)(2n+1)}{6}
$$

## Incomplete input

An incomplete inline expression such as $a^2 + b^2 should not crash the renderer.
