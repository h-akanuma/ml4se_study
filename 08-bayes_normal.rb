# ベイズ推定による正規分布の推定

require 'rubystats/normal_distribution'
require 'nyaplot'

class Array
  def mean
    self.inject(:+) / self.size.to_f
  end
end

def normal_rand(mu = 0, sigma = 1.0)
  random = Random.new
  (Math.sqrt(-2 * Math.log(random.rand)) * Math.sin(2 * Math::PI * random.rand) * sigma) + mu
end

DATA_COUNTS = [2, 4, 10, 100]

# 真の分布
MU_TRUE = 2.0
BETA_TRUE = 1.0

# 事前分布
MU_0 = -2.0
BETA_0 = 1.0

ds = 100.times.map do
  normal_rand(MU_TRUE, 1.0 / BETA_TRUE)
end

fig1 = Nyaplot::Frame.new
fig2 = Nyaplot::Frame.new

DATA_COUNTS.each_with_index do |n, c|
  train_set = ds[0..n-1]
  mu_ML = train_set.mean
  mu_N = (BETA_TRUE * mu_ML + BETA_0 * MU_0 / n) / (BETA_TRUE + BETA_0 / n)
  beta_N = BETA_0 + n * BETA_TRUE

# 平均μの推定結果を表示
  plot = Nyaplot::Plot.new
  linex = (-10..10).step(0.01).to_a

  # 平均μの確率分布
  sigma = 1.0 / beta_N
  mu_est = Rubystats::NormalDistribution.new(mu_N, Math.sqrt(sigma))
  label = "mu_N=%.2f var=%.2f" % [mu_N, sigma]
  liney = linex.map {|x| mu_est.pdf(x) }
  line = plot.add(:line, linex, liney)
  line.title(label)
  line.color('red')

  # トレーニングセットを表示
  scatter = plot.add(:scatter, train_set, [0.2] * n)
  scatter.title('train_set')
  scatter.color('blue')

  plot.configure do
    x_label("N=#{n}")
    y_label('')
    xrange([-5, 5])
    yrange([0, liney.max * 1.1])
    legend(true)
    height(300)
    width(490)
  end

  fig1.add(plot)

# 次に得られるデータの推定分布を表示
  plot = Nyaplot::Plot.new
  
  # 真の分布を表示
  orig = Rubystats::NormalDistribution.new(MU_TRUE, Math.sqrt(1.0 / BETA_TRUE))
  liney = linex.map {|x| orig.pdf(x)}
  y_max = liney.max * 1.1
  line = plot.add(:line, linex, liney)
  line.title('original')
  line.color('green')
  
  # 推定分布を表示
  sigma = 1.0 / BETA_TRUE + 1.0 / beta_N
  mu_est = Rubystats::NormalDistribution.new(mu_N, Math.sqrt(sigma))
  label = "mu_N=%.2f var=%.2f" % [mu_N, sigma]
  liney = linex.map {|x| mu_est.pdf(x) }
  line = plot.add(:line, linex, liney)
  line.title(label)
  line.color('red')
  
  # トレーニングセットを表示
  scatter = plot.add(:scatter, train_set, train_set.map {|x| orig.pdf(x) })
  scatter.title('train_set')
  scatter.color('blue')

  plot.configure do
    x_label("N=#{n}")
    y_label('')
    xrange([-5, 5])
    yrange([0, y_max])
    legend(true)
    height(300)
    width(490)
  end

  fig2.add(plot)
end

fig1.show
fig2.show
