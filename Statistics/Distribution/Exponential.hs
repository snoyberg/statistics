{-# LANGUAGE DeriveDataTypeable, DeriveGeneric, CPP #-}
-- |
-- Module    : Statistics.Distribution.Exponential
-- Copyright : (c) 2009 Bryan O'Sullivan
-- License   : BSD3
--
-- Maintainer  : bos@serpentine.com
-- Stability   : experimental
-- Portability : portable
--
-- The exponential distribution.  This is the continunous probability
-- distribution of the times between events in a poisson process, in
-- which events occur continuously and independently at a constant
-- average rate.

module Statistics.Distribution.Exponential
    (
      ExponentialDistribution
    -- * Constructors
    , exponential
    , exponentialFromSample
    -- * Accessors
    , edLambda
    ) where

import Data.Binary (Binary)
import Data.Data (Data, Typeable)
import GHC.Generics (Generic)
import Numeric.MathFunctions.Constants (m_neg_inf)
import qualified Statistics.Distribution         as D
import qualified Statistics.Sample               as S
import qualified System.Random.MWC.Distributions as MWC
import Statistics.Types (Sample)
#if !MIN_VERSION_binary(0, 6, 0)
import Data.Binary (put, get)
#endif


newtype ExponentialDistribution = ED {
      edLambda :: Double
    } deriving (Eq, Read, Show, Typeable, Data, Generic)

instance Binary ExponentialDistribution where
#if !MIN_VERSION_binary(0, 6, 0)
    put = put . edLambda
    get = fmap ED get
#endif

instance D.Distribution ExponentialDistribution where
    cumulative      = cumulative
    complCumulative = complCumulative

instance D.ContDistr ExponentialDistribution where
    density (ED l) x
      | x < 0     = 0
      | otherwise = l * exp (-l * x)
    logDensity (ED l) x
      | x < 0     = m_neg_inf
      | otherwise = log l + (-l * x)
    quantile = quantile

instance D.Mean ExponentialDistribution where
    mean (ED l) = 1 / l
    {-# INLINE mean #-}

instance D.Variance ExponentialDistribution where
    variance (ED l) = 1 / (l * l)
    {-# INLINE variance #-}

instance D.MaybeMean ExponentialDistribution where
    maybeMean = Just . D.mean

instance D.MaybeVariance ExponentialDistribution where
    maybeStdDev   = Just . D.stdDev
    maybeVariance = Just . D.variance

instance D.Entropy ExponentialDistribution where
  entropy (ED l) = 1 - log l

instance D.MaybeEntropy ExponentialDistribution where
  maybeEntropy = Just . D.entropy

instance D.ContGen ExponentialDistribution where
  genContVar = MWC.exponential . edLambda

cumulative :: ExponentialDistribution -> Double -> Double
cumulative (ED l) x | x <= 0    = 0
                    | otherwise = 1 - exp (-l * x)
{-# INLINE cumulative #-}

complCumulative :: ExponentialDistribution -> Double -> Double
complCumulative (ED l) x | x <= 0    = 1
                         | otherwise = exp (-l * x)
{-# INLINE complCumulative #-}


quantile :: ExponentialDistribution -> Double -> Double
quantile (ED l) p
  | p == 1          = 1 / 0
  | p >= 0 && p < 1 = -log (1 - p) / l
  | otherwise       =
    error $ "Statistics.Distribution.Exponential.quantile: p must be in [0,1] range. Got: "++show p
{-# INLINE quantile #-}

-- | Create an exponential distribution.
exponential :: Double            -- ^ &#955; (scale) parameter.
            -> ExponentialDistribution
exponential l
  | l <= 0 =
    error $ "Statistics.Distribution.Exponential.exponential: scale parameter must be positive. Got " ++ show l
  | otherwise = ED l
{-# INLINE exponential #-}

-- | Create exponential distribution from sample. No tests are made to
-- check whether it truly is exponential.
exponentialFromSample :: Sample -> ExponentialDistribution
exponentialFromSample = ED . S.mean
{-# INLINE exponentialFromSample #-}
