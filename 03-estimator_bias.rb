# 推定量の一致性と不偏性の確認

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

def thin_out_data(array)
  array.values_at(*(0...array.size-1).step(50))
end

def draw_plot(linex1, liney1, linex2, liney2, label, ylim)
  plot = Nyaplot::Plot.new
  df = Nyaplot::DataFrame.new(x: linex1, y: liney1)
  scatter = plot.add_with_df(df, :scatter, :x, :y)
  scatter.color('blue')
  scatter.title('data')
  line = plot.add(:line, linex2, liney2)
  line.color('red')
  line.title('mean')

  plot.configure do
    x_label(label)
    y_label('')
    xrange([linex1.min, linex1.max + 1])
    yrange(ylim)
    legend(true)
  end
end

mean_linex = []
mean_mu = []
mean_s2 = []
mean_u2 = []
raw_linex = []
raw_mu = []
raw_s2 = []
raw_u2 = []

(2..50).each do |n| # 観測データ数Nを変化させて実行
  2000.times do # 特定のNについて2000回の推定を繰り返す
    ds = n.times.map { normal_rand }
    raw_mu << ds.mean
    sum_of_squares = ds.inject(0) {|sum, i| sum + (i - ds.mean) ** 2 }
    var = sum_of_squares / ds.size.to_f
    raw_s2 << var
    raw_u2 << var * n / (n - 1)
    raw_linex << n
  end

  mean_mu << raw_mu.mean # 標本平均の平均
  mean_s2 << raw_s2.mean # 標本分散の平均
  mean_u2 << raw_u2.mean # 不偏分散の平均
  mean_linex << n
end

# プロットデータを40個に間引きする
raw_linex = thin_out_data(raw_linex)
raw_mu = thin_out_data(raw_mu)
raw_s2 = thin_out_data(raw_s2)
raw_u2 = thin_out_data(raw_u2)

fig = Nyaplot::Frame.new

# 標本平均の結果表示
plot = draw_plot(raw_linex, raw_mu, mean_linex, mean_mu, 'Sample mean', [-1.5, 1.5])
fig.add(plot)

# 標本分散の結果表示
plot = draw_plot(raw_linex, raw_s2, mean_linex, mean_s2, 'Sample variance', [-0.5, 3.0])
fig.add(plot)

# 不偏分散の結果表示
plot = draw_plot(raw_linex, raw_u2, mean_linex, mean_u2, 'Unbiased variance', [-0.5, 3.0])
fig.add(plot)

fig.show
