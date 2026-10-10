"""Normal distribution of a random variable (port of statistics.NormalDist)."""
import from types { NotImplementedType }
import from math { hypot, sqrt, fabs, exp, erf, tau, log, fsum }

glob SQRT2: float = sqrt(2.0);

class StatisticsError(ValueError) {}

"""Sample mean and sample standard deviation."""
def mean_stdev(data: list[float]) -> tuple[float, float] {
    xs = [float(x) for x in data];
    n = len(xs);
    if n < 2 {
        raise StatisticsError("stdev requires at least two data points");
    }
    xbar = fsum(xs) / n;
    ss = fsum([(x - xbar) ** 2 for x in xs]);
    return (xbar, sqrt(ss / (n - 1)));
}

"""Evaluate a polynomial (Horner) with coefficients from highest degree down."""
def horner(coeffs: list[float], r: float) -> float {
    acc = 0.0;
    for c in coeffs {
        acc = acc * r + c;
    }
    return acc;
}

glob CENTRAL_NUM: list[float] = [2.50908_09287_30122_6727e+3, 3.34305_75583_58812_8105e+4,
                                 6.72657_70927_00870_0853e+4, 4.59219_53931_54987_1457e+4,
                                 1.37316_93765_50946_1125e+4, 1.97159_09503_06551_4427e+3,
                                 1.33141_66789_17843_7745e+2, 3.38713_28727_96366_6080e+0],
     CENTRAL_DEN: list[float] = [5.22649_52788_52854_5610e+3, 2.87290_85735_72194_2674e+4,
                                 3.93078_95800_09271_0610e+4, 2.12137_94301_58659_5867e+4,
                                 5.39419_60214_24751_1077e+3, 6.87187_00749_20579_0830e+2,
                                 4.23133_30701_60091_1252e+1, 1.0],
     MID_NUM: list[float] = [7.74545_01427_83414_07640e-4, 2.27238_44989_26918_45833e-2,
                             2.41780_72517_74506_11770e-1, 1.27045_82524_52368_38258e+0,
                             3.64784_83247_63204_60504e+0, 5.76949_72214_60691_40550e+0,
                             4.63033_78461_56545_29590e+0, 1.42343_71107_49683_57734e+0],
     MID_DEN: list[float] = [1.05075_00716_44416_84324e-9, 5.47593_80849_95344_94600e-4,
                             1.51986_66563_61645_71966e-2, 1.48103_97642_74800_74590e-1,
                             6.89767_33498_51000_04550e-1, 1.67638_48301_83803_84940e+0,
                             2.05319_16266_37758_82187e+0, 1.0],
     TAIL_NUM: list[float] = [2.01033_43992_92288_13265e-7, 2.71155_55687_43487_57815e-5,
                              1.24266_09473_88078_43860e-3, 2.65321_89526_57612_30930e-2,
                              2.96560_57182_85048_91230e-1, 1.78482_65399_17291_33580e+0,
                              5.46378_49111_64114_36990e+0, 6.65790_46435_01103_77720e+0],
     TAIL_DEN: list[float] = [2.04426_31033_89939_78564e-15, 1.42151_17583_16445_88870e-7,
                              1.84631_83175_10054_68180e-5, 7.86869_13114_56132_59100e-4,
                              1.48753_61290_85061_48525e-2, 1.36929_88092_27358_05310e-1,
                              5.99832_20655_58879_37690e-1, 1.0];

"""Wichura (1988) Algorithm AS241 rational approximation of the inverse CDF."""
def normal_dist_inv_cdf(p: float, mu: float, sigma: float) -> float {
    q = p - 0.5;
    if fabs(q) <= 0.425 {
        r = 0.180625 - q * q;
        x = horner(CENTRAL_NUM, r) * q / horner(CENTRAL_DEN, r);
        return mu + (x * sigma);
    }
    r = p if q <= 0.0 else 1.0 - p;
    r = sqrt(-log(r));
    x: float = 0.0;
    if r <= 5.0 {
        r = r - 1.6;
        x = horner(MID_NUM, r) / horner(MID_DEN, r);
    } else {
        r = r - 5.0;
        x = horner(TAIL_NUM, r) / horner(TAIL_DEN, r);
    }
    if q < 0.0 {
        x = -x;
    }
    return mu + (x * sigma);
}

obj NormalDist {
    has mu: float = 0.0,
        sigma: float = 1.0;

    def postinit {
        if self.sigma < 0.0 {
            raise StatisticsError("sigma must be non-negative");
        }
        self.mu = float(self.mu);
        self.sigma = float(self.sigma);
    }

    """Make a normal distribution from sample data."""
    static def from_samples(data: list[float]) -> NormalDist {
        (m, s) = mean_stdev(list(data));
        return NormalDist(m, s);
    }

    has mean: float { getter -> float { return self.mu; } }
    has median: float { getter -> float { return self.mu; } }
    has mode: float { getter -> float { return self.mu; } }
    has stdev: float { getter -> float { return self.sigma; } }
    has variance: float { getter -> float { return self.sigma * self.sigma; } }

    """Probability density function.  P(x <= X < x+dx) / dx"""
    def pdf(x: float) -> float {
        variance = self.sigma * self.sigma;
        if not variance {
            raise StatisticsError("pdf() not defined when sigma is zero");
        }
        diff = x - self.mu;
        return exp(diff * diff / (-2.0 * variance)) / sqrt(tau * variance);
    }

    """Cumulative distribution function.  P(X <= x)"""
    def cdf(x: float) -> float {
        if not self.sigma {
            raise StatisticsError("cdf() not defined when sigma is zero");
        }
        return 0.5 * (1.0 + erf((x - self.mu) / (self.sigma * SQRT2)));
    }

    """Inverse CDF: the x with P(X <= x) = p."""
    def inv_cdf(p: float) -> float {
        if p <= 0.0 or p >= 1.0 {
            raise StatisticsError("p must be in the range 0.0 < p < 1.0");
        }
        return normal_dist_inv_cdf(p, self.mu, self.sigma);
    }

    """n - 1 cut points dividing the distribution into n equal-probability intervals."""
    def quantiles(n: int = 4) -> list[float] {
        return [self.inv_cdf(i / n) for i in range(1, n)];
    }

    """Overlapping coefficient (OVL) between two normal distributions."""
    def overlap(other: NormalDist) -> float {
        if not isinstance(other, NormalDist) {
            raise TypeError("Expected another NormalDist instance");
        }
        (X, Y) = (self, other);
        if (Y.sigma, Y.mu) < (X.sigma, X.mu) {
            (X, Y) = (Y, X);
        }
        (X_var, Y_var) = (X.variance, Y.variance);
        if not X_var or not Y_var {
            raise StatisticsError("overlap() not defined when sigma is zero");
        }
        dv = Y_var - X_var;
        dm = fabs(Y.mu - X.mu);
        if not dv {
            return 1.0 - erf(dm / (2.0 * X.sigma * SQRT2));
        }
        a = X.mu * Y_var - Y.mu * X_var;
        b = X.sigma * Y.sigma * sqrt(dm * dm + dv * log(Y_var / X_var));
        x1 = (a + b) / dv;
        x2 = (a - b) / dv;
        return 1.0 - (fabs(Y.cdf(x1) - X.cdf(x1)) + fabs(Y.cdf(x2) - X.cdf(x2)));
    }

    """Standard score (x - mean) / stdev."""
    def zscore(x: float) -> float {
        if not self.sigma {
            raise StatisticsError("zscore() not defined when sigma is zero");
        }
        return (x - self.mu) / self.sigma;
    }

    def __add__(other: NormalDist | float) -> NormalDist {
        if isinstance(other, NormalDist) {
            return NormalDist(self.mu + other.mu, hypot(self.sigma, other.sigma));
        }
        return NormalDist(self.mu + other, self.sigma);
    }

    def __radd__(other: float) -> NormalDist {
        return self.__add__(other);
    }

    def __sub__(other: NormalDist | float) -> NormalDist {
        if isinstance(other, NormalDist) {
            return NormalDist(self.mu - other.mu, hypot(self.sigma, other.sigma));
        }
        return NormalDist(self.mu - other, self.sigma);
    }

    def __rsub__(other: float) -> NormalDist {
        return -(self - other);
    }

    def __mul__(k: float) -> NormalDist {
        return NormalDist(self.mu * k, self.sigma * fabs(k));
    }

    def __rmul__(k: float) -> NormalDist {
        return self.__mul__(k);
    }

    def __truediv__(k: float) -> NormalDist {
        return NormalDist(self.mu / k, self.sigma / fabs(k));
    }

    def __pos__ -> NormalDist {
        return NormalDist(self.mu, self.sigma);
    }

    def __neg__ -> NormalDist {
        return NormalDist(-self.mu, self.sigma);
    }

    def __eq__(other: object) -> bool | NotImplementedType {
        if not isinstance(other, NormalDist) {
            return NotImplemented;
        }
        return self.mu == other.mu and self.sigma == other.sigma;
    }

    def __hash__ -> int {
        return hash((self.mu, self.sigma));
    }

    def __repr__ -> str {
        return f"{type(self).__name__}(mu={self.mu!r}, sigma={self.sigma!r})";
    }
}
