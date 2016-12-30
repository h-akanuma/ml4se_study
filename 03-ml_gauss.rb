require 'nyaplot'
require 'rubystats/normal_distribution'

def normal_rand(mu = 0, sigma = 1.0)
  random = Random.new
  (Math.sqrt(-2 * Math.log(random.rand)) * Math.sin(2 * Math::PI * random.rand) * sigma) + mu
end

fig = Nyaplot::Frame.new

[2,4,10,100].each do |datapoints|
  ds = datapoints.times.map { normal_rand }

  mu = ds.inject(:+) / ds.size.to_f
  sum_of_squares = ds.inject(0) {|sum, i| sum + (i - mu) ** 2} 
  var = sum_of_squares / ds.size.to_f
  sigma = Math.sqrt(var)

  plot = Nyaplot::Plot.new

  s = 0.1
  linex = (-10..10-s).step(s).to_a
  
  # 真の曲線を表示
  orig = Rubystats::NormalDistribution.new(0, 1)  
  orig_pdfs = linex.map {|x| orig.pdf(x) }
  line = plot.add(:line, linex, orig_pdfs)
  line.color('green')
  line.title('Original')

  # 推定した曲線を表示
  est = Rubystats::NormalDistribution.new(mu, Math.sqrt(sigma))
  est_pdfs = linex.map {|x| est.pdf(x)}
  line = plot.add(:line, linex, est_pdfs)
  line.color('red')
  line.title("Sigma=#{sprintf("%.2f", sigma)}")
  
  # サンプルの表示
  df = Nyaplot::DataFrame.new({x: ds,y: ds.map {|x| orig.pdf(x)}})
  scatter = plot.add_with_df(df, :scatter, :x, :y)
  scatter.color('blue')
  scatter.title('Sample')

  fig.add(plot)
  
  plot.configure do
    x_label("N=#{datapoints}")
    y_label('')
    xrange([-4, 4])
    legend(true)
    height(300)
    width(490)
  end
end

fig.show
