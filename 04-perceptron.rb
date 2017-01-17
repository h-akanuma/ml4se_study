require 'daru'
require 'nyaplot'
require 'numo/narray'

N1 = 20
Mu1 = [15, 10]

N2 = 30
Mu2 = [0, 0]

Variances = [15, 30]

class Array
  def mean
    self.inject(:+) / self.size.to_f
  end
end

def normal_rand(mu = 0, sigma = 1.0)
  random = Random.new
  (Math.sqrt(-2 * Math.log(random.rand)) * Math.sin(2 * Math::PI * random.rand) * sigma) + mu
end

# データセット {x_n,y_n,type_n} を用意
def prepare_dataset(variance)
  sigma = Math.sqrt(variance)

  df1 = N1.times.map do
    [normal_rand(Mu1[0], sigma), normal_rand(Mu1[1], sigma)]
  end
  df1 = df1.transpose
  df1 = Daru::DataFrame.new(x: df1[0], y: df1[1], type: Array.new(N1).fill(1))

  df2 = N2.times.map do
    [normal_rand(Mu2[0], sigma), normal_rand(Mu2[1], sigma)]
  end
  df2 = df2.transpose
  df2 = Daru::DataFrame.new(x: df2[0], y: df2[1], type: Array.new(N2).fill(-1))

  df = df1.concat(df2)
  df = df.reindex(Daru::Index.new(df.index.to_a.shuffle))
  df[:index] = (N1 + N2).times.to_a
  df.set_index(:index)
end

# Perceptronのアルゴリズム（確率的勾配降下法）を実行
def run_simulation(variance)
  data_graph = Nyaplot::Plot.new
  param_graph = Nyaplot::Plot.new

  train_set = prepare_dataset(variance)
  train_set1 = train_set.filter_rows {|row| row[:type] == 1 }
  train_set2 = train_set.filter_rows {|row| row[:type] == -1 }
  ymin = train_set.y.min - 5
  xmin = train_set.x.min - 5
  ymax = train_set.y.max + 10
  xmax = train_set.x.max + 10
  data_graph.configure do
    x_label('')
    y_label('')
    xrange([xmin, xmax])
    yrange([ymin, ymax])
    legend(true)
    height(300)
    width(490)
  end

  scatter_true = data_graph.add_with_df(train_set1.to_nyaplotdf, :scatter, :x, :y)
  scatter_true.color('green')
  scatter_true.title('1')
  scatter_false = data_graph.add_with_df(train_set2.to_nyaplotdf, :scatter, :x, :y)
  scatter_false.color('orange')
  scatter_false.title('-1')
  
  # パラメータの初期値とbias項の設定
  w0 = 0.0
  w1 = 0.0
  w2 = 0.0
  bias = 0.5 * (train_set.x.mean + train_set.y.mean)
    
  # Iterationを30回実施
  paramhist = Daru::DataFrame.new(w0: [w0], w1: [w1], w2: [w2])
  30.times do
    train_set.each_row do |point|
      x = point.x
      y = point.y
      type = point[:type]
      if type * (w0*bias + w1*x + w2*y) <= 0
        w0 += type * bias
        w1 += type * x
        w2 += type * y
      end
    end
    paramhist.add_row(Daru::Vector.new([w0, w1, w2], index: [:w0, :w1, :w2]))
  end
  
  # 判定誤差の計算
  err = 0
  train_set.each_row do |point|
    x = point.x
    y = point.y
    type = point[:type]
    if type * (w0*bias + w1*x + w2*y) <= 0
      err += 1
    end
  end
  
  err_rate = err * 100 / train_set.size
  
  # 結果の表示
  linex = Numo::NArray[*(xmin.to_i-5..xmax.to_i+4).to_a]
  liney = -linex * w1 / w2 - bias * w0 / w2
  label = "ERR %.2f%%" % err_rate
  line_err = data_graph.add(:line, linex.cast_to(Numo::Int64).to_a, liney.cast_to(Numo::Int64).to_a)
  line_err.title(label)
  line_err.color('red')
  line_w0 = param_graph.add(:line, paramhist.index.to_a, paramhist.w0)
  line_w0.title('w0')
  line_w0.color('blue')
  line_w1 = param_graph.add(:line, paramhist.index.to_a, paramhist.w1)
  line_w1.title('w1')
  line_w1.color('green')
  line_w2 = param_graph.add(:line, paramhist.index.to_a, paramhist.w2)
  line_w2.title('w2')
  line_w2.color('red')
  
  param_graph.configure do
    x_label('')
    y_label('')
    legend(true)
    height(300)
    width(490)
  end

  [data_graph, param_graph]
end

fig = Nyaplot::Frame.new

Variances.each do |variance|
  data_graph, param_graph = run_simulation(variance)
  fig.add(data_graph)
  fig.add(param_graph)
end

fig.show

