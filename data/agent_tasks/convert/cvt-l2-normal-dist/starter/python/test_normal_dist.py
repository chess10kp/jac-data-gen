"""Unit tests for normal_dist.NormalDist.

Adapted from CPython 3.12.7 Lib/test/test_statistics.py (class TestNormalDist),
PSF License Version 2. Tests for samples(), __slots__, copy and pickle were
dropped along with those features.
"""
import math
import unittest

import normal_dist


class TestNormalDist(unittest.TestCase):
    module = normal_dist


    # General note on precision: The pdf(), cdf(), and overlap() methods
    # depend on functions in the math libraries that do not make
    # explicit accuracy guarantees.  Accordingly, some of the accuracy
    # tests below may fail if the underlying math functions are
    # inaccurate.  There isn't much we can do about this short of
    # implementing our own implementations from scratch.


    def test_instantiation_and_attributes(self):
        nd = self.module.NormalDist(500, 17)
        self.assertEqual(nd.mean, 500)
        self.assertEqual(nd.stdev, 17)
        self.assertEqual(nd.variance, 17**2)

        # default arguments
        nd = self.module.NormalDist()
        self.assertEqual(nd.mean, 0)
        self.assertEqual(nd.stdev, 1)
        self.assertEqual(nd.variance, 1**2)

        # error case: negative sigma
        with self.assertRaises(self.module.StatisticsError):
            self.module.NormalDist(500, -10)

        # verify that subclass type is honored
        class NewNormalDist(self.module.NormalDist):
            pass
        nnd = NewNormalDist(200, 5)
        self.assertEqual(type(nnd), NewNormalDist)

    def test_alternative_constructor(self):
        NormalDist = self.module.NormalDist
        data = [96, 107, 90, 92, 110]
        # list input
        self.assertEqual(NormalDist.from_samples(data), NormalDist(99, 9))
        # tuple input
        self.assertEqual(NormalDist.from_samples(tuple(data)), NormalDist(99, 9))
        # iterator input
        self.assertEqual(NormalDist.from_samples(iter(data)), NormalDist(99, 9))
        # error cases
        with self.assertRaises(self.module.StatisticsError):
            NormalDist.from_samples([])                      # empty input
        with self.assertRaises(self.module.StatisticsError):
            NormalDist.from_samples([10])                    # only one input

        # verify that subclass type is honored
        class NewNormalDist(NormalDist):
            pass
        nnd = NewNormalDist.from_samples(data)
        self.assertEqual(type(nnd), NewNormalDist)


    def test_pdf(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 15)
        # Verify peak around center
        self.assertLess(X.pdf(99), X.pdf(100))
        self.assertLess(X.pdf(101), X.pdf(100))
        # Test symmetry
        for i in range(50):
            self.assertAlmostEqual(X.pdf(100 - i), X.pdf(100 + i))
        # Test vs CDF
        dx = 2.0 ** -10
        for x in range(90, 111):
            est_pdf = (X.cdf(x + dx) - X.cdf(x)) / dx
            self.assertAlmostEqual(X.pdf(x), est_pdf, places=4)
        # Test vs table of known values -- CRC 26th Edition
        Z = NormalDist()
        for x, px in enumerate([
            0.3989, 0.3989, 0.3989, 0.3988, 0.3986,
            0.3984, 0.3982, 0.3980, 0.3977, 0.3973,
            0.3970, 0.3965, 0.3961, 0.3956, 0.3951,
            0.3945, 0.3939, 0.3932, 0.3925, 0.3918,
            0.3910, 0.3902, 0.3894, 0.3885, 0.3876,
            0.3867, 0.3857, 0.3847, 0.3836, 0.3825,
            0.3814, 0.3802, 0.3790, 0.3778, 0.3765,
            0.3752, 0.3739, 0.3725, 0.3712, 0.3697,
            0.3683, 0.3668, 0.3653, 0.3637, 0.3621,
            0.3605, 0.3589, 0.3572, 0.3555, 0.3538,
        ]):
            self.assertAlmostEqual(Z.pdf(x / 100.0), px, places=4)
            self.assertAlmostEqual(Z.pdf(-x / 100.0), px, places=4)
        # Error case: variance is zero
        Y = NormalDist(100, 0)
        with self.assertRaises(self.module.StatisticsError):
            Y.pdf(90)
        # Special values
        self.assertEqual(X.pdf(float('-Inf')), 0.0)
        self.assertEqual(X.pdf(float('Inf')), 0.0)
        self.assertTrue(math.isnan(X.pdf(float('NaN'))))

    def test_cdf(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 15)
        cdfs = [X.cdf(x) for x in range(1, 200)]
        self.assertEqual(set(map(type, cdfs)), {float})
        # Verify montonic
        self.assertEqual(cdfs, sorted(cdfs))
        # Verify center (should be exact)
        self.assertEqual(X.cdf(100), 0.50)
        # Check against a table of known values
        # https://en.wikipedia.org/wiki/Standard_normal_table#Cumulative
        Z = NormalDist()
        for z, cum_prob in [
            (0.00, 0.50000), (0.01, 0.50399), (0.02, 0.50798),
            (0.14, 0.55567), (0.29, 0.61409), (0.33, 0.62930),
            (0.54, 0.70540), (0.60, 0.72575), (1.17, 0.87900),
            (1.60, 0.94520), (2.05, 0.97982), (2.89, 0.99807),
            (3.52, 0.99978), (3.98, 0.99997), (4.07, 0.99998),
            ]:
            self.assertAlmostEqual(Z.cdf(z), cum_prob, places=5)
            self.assertAlmostEqual(Z.cdf(-z), 1.0 - cum_prob, places=5)
        # Error case: variance is zero
        Y = NormalDist(100, 0)
        with self.assertRaises(self.module.StatisticsError):
            Y.cdf(90)
        # Special values
        self.assertEqual(X.cdf(float('-Inf')), 0.0)
        self.assertEqual(X.cdf(float('Inf')), 1.0)
        self.assertTrue(math.isnan(X.cdf(float('NaN'))))

    def test_inv_cdf(self):
        NormalDist = self.module.NormalDist

        # Center case should be exact.
        iq = NormalDist(100, 15)
        self.assertEqual(iq.inv_cdf(0.50), iq.mean)

        # Test versus a published table of known percentage points.
        # See the second table at the bottom of the page here:
        # http://people.bath.ac.uk/masss/tables/normaltable.pdf
        Z = NormalDist()
        pp = {5.0: (0.000, 1.645, 2.576, 3.291, 3.891,
                    4.417, 4.892, 5.327, 5.731, 6.109),
              2.5: (0.674, 1.960, 2.807, 3.481, 4.056,
                    4.565, 5.026, 5.451, 5.847, 6.219),
              1.0: (1.282, 2.326, 3.090, 3.719, 4.265,
                    4.753, 5.199, 5.612, 5.998, 6.361)}
        for base, row in pp.items():
            for exp, x in enumerate(row, start=1):
                p = base * 10.0 ** (-exp)
                self.assertAlmostEqual(-Z.inv_cdf(p), x, places=3)
                p = 1.0 - p
                self.assertAlmostEqual(Z.inv_cdf(p), x, places=3)

        # Match published example for MS Excel
        # https://support.office.com/en-us/article/norm-inv-function-54b30935-fee7-493c-bedb-2278a9db7e13
        self.assertAlmostEqual(NormalDist(40, 1.5).inv_cdf(0.908789), 42.000002)

        # One million equally spaced probabilities
        n = 2**20
        for p in range(1, n):
            p /= n
            self.assertAlmostEqual(iq.cdf(iq.inv_cdf(p)), p)

        # One hundred ever smaller probabilities to test tails out to
        # extreme probabilities: 1 / 2**50 and (2**50-1) / 2 ** 50
        for e in range(1, 51):
            p = 2.0 ** (-e)
            self.assertAlmostEqual(iq.cdf(iq.inv_cdf(p)), p)
            p = 1.0 - p
            self.assertAlmostEqual(iq.cdf(iq.inv_cdf(p)), p)

        # Now apply cdf() first.  Near the tails, the round-trip loses
        # precision and is ill-conditioned (small changes in the inputs
        # give large changes in the output), so only check to 5 places.
        for x in range(200):
            self.assertAlmostEqual(iq.inv_cdf(iq.cdf(x)), x, places=5)

        # Error cases:
        with self.assertRaises(self.module.StatisticsError):
            iq.inv_cdf(0.0)                         # p is zero
        with self.assertRaises(self.module.StatisticsError):
            iq.inv_cdf(-0.1)                        # p under zero
        with self.assertRaises(self.module.StatisticsError):
            iq.inv_cdf(1.0)                         # p is one
        with self.assertRaises(self.module.StatisticsError):
            iq.inv_cdf(1.1)                         # p over one

        # Supported case:
        iq = NormalDist(100, 0)                     # sigma is zero
        self.assertEqual(iq.inv_cdf(0.5), 100)

        # Special values
        self.assertTrue(math.isnan(Z.inv_cdf(float('NaN'))))

    def test_quantiles(self):
        # Quartiles of a standard normal distribution
        Z = self.module.NormalDist()
        for n, expected in [
            (1, []),
            (2, [0.0]),
            (3, [-0.4307, 0.4307]),
            (4 ,[-0.6745, 0.0, 0.6745]),
                ]:
            actual = Z.quantiles(n=n)
            self.assertTrue(all(math.isclose(e, a, abs_tol=0.0001)
                            for e, a in zip(expected, actual)))

    def test_overlap(self):
        NormalDist = self.module.NormalDist

        # Match examples from Imman and Bradley
        for X1, X2, published_result in [
                (NormalDist(0.0, 2.0), NormalDist(1.0, 2.0), 0.80258),
                (NormalDist(0.0, 1.0), NormalDist(1.0, 2.0), 0.60993),
            ]:
            self.assertAlmostEqual(X1.overlap(X2), published_result, places=4)
            self.assertAlmostEqual(X2.overlap(X1), published_result, places=4)

        # Check against integration of the PDF
        def overlap_numeric(X, Y, *, steps=8_192, z=5):
            'Numerical integration cross-check for overlap() '
            fsum = math.fsum
            center = (X.mean + Y.mean) / 2.0
            width = z * max(X.stdev, Y.stdev)
            start = center - width
            dx = 2.0 * width / steps
            x_arr = [start + i*dx for i in range(steps)]
            xp = list(map(X.pdf, x_arr))
            yp = list(map(Y.pdf, x_arr))
            total = max(fsum(xp), fsum(yp))
            return fsum(map(min, xp, yp)) / total

        for X1, X2 in [
                # Examples from Imman and Bradley
                (NormalDist(0.0, 2.0), NormalDist(1.0, 2.0)),
                (NormalDist(0.0, 1.0), NormalDist(1.0, 2.0)),
                # Example from https://www.rasch.org/rmt/rmt101r.htm
                (NormalDist(0.0, 1.0), NormalDist(1.0, 2.0)),
                # Gender heights from http://www.usablestats.com/lessons/normal
                (NormalDist(70, 4), NormalDist(65, 3.5)),
                # Misc cases with equal standard deviations
                (NormalDist(100, 15), NormalDist(110, 15)),
                (NormalDist(-100, 15), NormalDist(110, 15)),
                (NormalDist(-100, 15), NormalDist(-110, 15)),
                # Misc cases with unequal standard deviations
                (NormalDist(100, 12), NormalDist(100, 15)),
                (NormalDist(100, 12), NormalDist(110, 15)),
                (NormalDist(100, 12), NormalDist(150, 15)),
                (NormalDist(100, 12), NormalDist(150, 35)),
                # Misc cases with small values
                (NormalDist(1.000, 0.002), NormalDist(1.001, 0.003)),
                (NormalDist(1.000, 0.002), NormalDist(1.006, 0.0003)),
                (NormalDist(1.000, 0.002), NormalDist(1.001, 0.099)),
            ]:
            self.assertAlmostEqual(X1.overlap(X2), overlap_numeric(X1, X2), places=5)
            self.assertAlmostEqual(X2.overlap(X1), overlap_numeric(X1, X2), places=5)

        # Error cases
        X = NormalDist()
        with self.assertRaises(TypeError):
            X.overlap()                             # too few arguments
        with self.assertRaises(TypeError):
            X.overlap(X, X)                         # too may arguments
        with self.assertRaises(TypeError):
            X.overlap(None)                         # right operand not a NormalDist
        with self.assertRaises(self.module.StatisticsError):
            X.overlap(NormalDist(1, 0))             # right operand sigma is zero
        with self.assertRaises(self.module.StatisticsError):
            NormalDist(1, 0).overlap(X)             # left operand sigma is zero

    def test_zscore(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 15)
        self.assertEqual(X.zscore(142), 2.8)
        self.assertEqual(X.zscore(58), -2.8)
        self.assertEqual(X.zscore(100), 0.0)
        with self.assertRaises(TypeError):
            X.zscore()                              # too few arguments
        with self.assertRaises(TypeError):
            X.zscore(1, 1)                          # too may arguments
        with self.assertRaises(TypeError):
            X.zscore(None)                          # non-numeric type
        with self.assertRaises(self.module.StatisticsError):
            NormalDist(1, 0).zscore(100)            # sigma is zero

    def test_properties(self):
        X = self.module.NormalDist(100, 15)
        self.assertEqual(X.mean, 100)
        self.assertEqual(X.median, 100)
        self.assertEqual(X.mode, 100)
        self.assertEqual(X.stdev, 15)
        self.assertEqual(X.variance, 225)

    def test_same_type_addition_and_subtraction(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 12)
        Y = NormalDist(40, 5)
        self.assertEqual(X + Y, NormalDist(140, 13))        # __add__
        self.assertEqual(X - Y, NormalDist(60, 13))         # __sub__

    def test_translation_and_scaling(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 15)
        y = 10
        self.assertEqual(+X, NormalDist(100, 15))           # __pos__
        self.assertEqual(-X, NormalDist(-100, 15))          # __neg__
        self.assertEqual(X + y, NormalDist(110, 15))        # __add__
        self.assertEqual(y + X, NormalDist(110, 15))        # __radd__
        self.assertEqual(X - y, NormalDist(90, 15))         # __sub__
        self.assertEqual(y - X, NormalDist(-90, 15))        # __rsub__
        self.assertEqual(X * y, NormalDist(1000, 150))      # __mul__
        self.assertEqual(y * X, NormalDist(1000, 150))      # __rmul__
        self.assertEqual(X / y, NormalDist(10, 1.5))        # __truediv__
        with self.assertRaises(TypeError):                  # __rtruediv__
            y / X

    def test_unary_operations(self):
        NormalDist = self.module.NormalDist
        X = NormalDist(100, 12)
        Y = +X
        self.assertIsNot(X, Y)
        self.assertEqual(X.mean, Y.mean)
        self.assertEqual(X.stdev, Y.stdev)
        Y = -X
        self.assertIsNot(X, Y)
        self.assertEqual(X.mean, -Y.mean)
        self.assertEqual(X.stdev, Y.stdev)

    def test_equality(self):
        NormalDist = self.module.NormalDist
        nd1 = NormalDist()
        nd2 = NormalDist(2, 4)
        nd3 = NormalDist()
        nd4 = NormalDist(2, 4)
        nd5 = NormalDist(2, 8)
        nd6 = NormalDist(8, 4)
        self.assertNotEqual(nd1, nd2)
        self.assertEqual(nd1, nd3)
        self.assertEqual(nd2, nd4)
        self.assertNotEqual(nd2, nd5)
        self.assertNotEqual(nd2, nd6)

        # Test NotImplemented when types are different
        class A:
            def __eq__(self, other):
                return 10
        a = A()
        self.assertEqual(nd1.__eq__(a), NotImplemented)
        self.assertEqual(nd1 == a, 10)
        self.assertEqual(a == nd1, 10)

        # All subclasses to compare equal giving the same behavior
        # as list, tuple, int, float, complex, str, dict, set, etc.
        class SizedNormalDist(NormalDist):
            def __init__(self, mu, sigma, n):
                super().__init__(mu, sigma)
                self.n = n
        s = SizedNormalDist(100, 15, 57)
        nd4 = NormalDist(100, 15)
        self.assertEqual(s, nd4)

        # Don't allow duck type equality because we wouldn't
        # want a lognormal distribution to compare equal
        # to a normal distribution with the same parameters
        class LognormalDist:
            def __init__(self, mu, sigma):
                self.mu = mu
                self.sigma = sigma
        lnd = LognormalDist(100, 15)
        nd = NormalDist(100, 15)
        self.assertNotEqual(nd, lnd)



    def test_hashability(self):
        ND = self.module.NormalDist
        s = {ND(100, 15), ND(100.0, 15.0), ND(100, 10), ND(95, 15), ND(100, 15)}
        self.assertEqual(len(s), 3)

    def test_repr(self):
        nd = self.module.NormalDist(37.5, 5.625)
        self.assertEqual(repr(nd), 'NormalDist(mu=37.5, sigma=5.625)')

# Swapping the sys.modules['statistics'] is to solving the
# _pickle.PicklingError:
# Can't pickle <class 'statistics.NormalDist'>:
# it's not the same object as statistics.NormalDist


if __name__ == '__main__':
    unittest.main()
