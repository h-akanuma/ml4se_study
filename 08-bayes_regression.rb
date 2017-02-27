# ベイズ推定による回帰分析

require 'daru'
require 'numo/narray'
require 'open3'
require 'nyaplot'

DATASET_NUMS = [4, 5, 10, 100]

BETA = 1.0 / (0.3) ** 2 # 真の分布の分散
ALPHA = 1.0 / 100 ** 2  # 事前分布の分散
ORDER = 9               # 多項式の字数

def normal_rand(mu = 0, sigma = 1.0)
  random = Random.new
  (Math.sqrt(-2 * Math.log(random.rand)) * Math.sin(2 * Math::PI * random.rand) * sigma) + mu
end

# データセット {x_n,y_n} (n=1...N) を用意
def create_dataset(num)
  dataset = Daru::DataFrame.new({'x': [], 'y': []})  

  num.times do |i|
    x = i.to_f / (num - 1).to_f
    y = Math.sin(2 * Math::PI * x) + normal_rand(0, 0.3)
    dataset.add_row(Daru::Vector.new([x, y], index: [:x, :y]))
  end
  
  return dataset
end

# 事後分布に基づく推定曲線、および、事後分布の平均と分散を計算
def resolve(dataset, m)
  t = dataset.y

  columns = {}
  (m+1).times do |i|
    columns["x**#{i}"] = dataset.x ** i
  end
  phis = Daru::DataFrame.new(columns)

  phiphi = nil
  phis.each_row_with_index do |line, index|
    phi = Daru::DataFrame.new(x: line)
    if index == 0
      phiphi = phi.to_matrix * phi.transpose.to_matrix
    else
      phiphi += phi.to_matrix * phi.transpose.to_matrix
    end
  end

  s_inv = Matrix[*(ALPHA * Numo::DFloat.eye(m + 1))] + BETA * phiphi
  s = s_inv.inv # 事後分布の共分散行列

  # 平均 m(x)
  mean_fun = lambda {|x0|
    phi_x0 = Numo::NArray[*((m + 1).times.map {|i| (x0 ** i).to_a })]
    tmp = 0
    phis.each_row_with_index do |line, index|
      if index == 0
        tmp = t[index] * Numo::NArray[*line.to_a]
        next
      end

      tmp += t[index] * Numo::NArray[*line.to_a]
    end
    BETA * phi_x0.transpose.dot(Numo::NArray[*s.to_a]).dot(tmp)
  }

  # 標準偏差 s(x)
  deviation_fun = lambda {|x0|
    phi_x0 = Numo::NArray[*((m + 1).times.map {|i| (x0 ** i).to_a })]
    deviation = (1.0 / BETA + phi_x0.transpose.dot(Numo::NArray[*s.to_a]).dot(phi_x0)).map {|v| v < 0 ? Float::NAN : Math.sqrt(v) }
    deviation.diagonal
  }

  tmp = nil
  phis.each_row_with_index do |line, index|
    if index == 0
      tmp = t[index] * Numo::NArray[*line.to_a]
      next
    end

    tmp += t[index] * Numo::NArray[*line.to_a]
  end
  mean = BETA * Numo::NArray[*s.to_a].dot(tmp).flatten

  return mean_fun, deviation_fun, mean, s
end

fig1 = Nyaplot::Frame.new
fig2 = Nyaplot::Frame.new

DATASET_NUMS.each do |num|
  train_set = create_dataset(num)
  mean_fun, deviation_fun, mean, sigma = resolve(train_set, ORDER)
  command = "python -c 'import numpy; print numpy.random.multivariate_normal(#{mean.to_a.inspect}, #{sigma.to_a.inspect}, 4).tolist()'"
  output, std_error, status = Open3.capture3(command)
  ws_samples = Daru::DataFrame.rows(eval(output))
  
  # トレーニングセットを表示
  plot1 = Nyaplot::Plot.new
  scatter1 = plot1.add(:scatter, train_set.x.to_a, train_set.y.to_a)
  scatter1.color('blue')
  scatter1.title('train_set')
  
  plot1.configure do
    x_label("N=#{num}")
    y_label('')
    xrange([-0.05, 1.05])
    yrange([-2, 2])
    legend(true)
    height(300)
    width(490)
  end
  
  plot2 = Nyaplot::Plot.new
  scatter2 = plot2.add(:scatter, train_set.x.to_a, train_set.y.to_a)
  scatter2.color('blue')
  scatter2.title('train_set')

  plot2.configure do
    x_label("N=#{num}")
    y_label('')
    xrange([-0.05, 1.05])
    yrange([-2, 2])
    legend(true)
    height(300)
    width(490)
  end
  
  linex = Numo::NArray[*(0..1).step(0.01).to_a]

  # 真の曲線を表示
  liney = (2 * Math::PI * linex).map {|v| Math.sin(v) }
  collect_line = plot1.add(:line, linex, liney)
  collect_line.color('green')
  collect_line.title('collect')

  # 平均と標準偏差の曲線を表示
  m = mean_fun.call(linex)
  d = deviation_fun.call(linex)
  mean_line = plot1.add(:line, linex, m)
  mean_line.color('red')
  mean_line.title('mean')
  lower_std_line = plot1.add(:line, linex, m - d)
  lower_std_line.color('black')
  lower_std_line.title('')
  upper_std_line = plot1.add(:line, linex, m + d)
  upper_std_line.color('black')
  upper_std_line.title('')

  # 多項式のサンプルを表示
  liney = m
  mean_line = plot2.add(:line, linex, liney)
  mean_line.color('red')
  mean_line.title('mean')
  
  f = lambda {|x, ws|
    y = 0
    ws.each_with_index do |w, i|
      y += w * (x ** i.to_i)
    end
    y
  }

  ws_samples.each_row do |ws|
    liney = f.call(linex, ws)
    sample_line = plot2.add(:line, linex, liney)
    sample_line.color('pink')
    sample_line.title('sample')
  end
  
  fig1.add(plot1)
  fig2.add(plot2)
end

fig1.show
fig2.show
