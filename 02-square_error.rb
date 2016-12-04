require 'daru'
require 'nyaplot'

N = 10
M = [0, 1, 3, 9]

def normal_rand(mu = 0, sigma = 1.0)
  random = Random.new
  (Math.sqrt(-2 * Math.log(random.rand)) * Math.sin(2 * Math::PI * random.rand) * sigma) + mu
end


def create_dataset(num)
  dataset = Daru::DataFrame.new({'x': [], 'y': []})  

  num.times do |i|
    x = i.to_f / (num - 1).to_f
    y = Math.sin(2 * Math::PI * x) + normal_rand(0, 0.3)
    dataset.add_row(Daru::Vector.new([x, y], index: [:x, :y]))
  end
  
  return dataset
end

def rms_error(dataset, f)
  err = 0.0
  dataset.each_row do |line|
    err += 0.5 * (line.y - f.call(line.x))**2
  end

  Math.sqrt(2 * err / dataset.size)
end

def resolve(dataset, m)
  t = dataset.y

  columns = {}
  (m+1).times do |i|
    columns["x**#{i}"] = dataset.x ** i
  end
  phi = Daru::DataFrame.new(columns)

  tmp = (phi.transpose.to_matrix * phi.to_matrix).inv
  ws = (tmp * phi.transpose.to_matrix) * Vector.elements(t.to_a)

  f = lambda {|x|
    y = 0
    ws.each_with_index do |w, i|
      y += w * (x ** i)
    end

    y
  }

  return f, ws
end

train_set = create_dataset(N)
test_set = create_dataset(N)
df_ws = {}

fig = Nyaplot::Frame.new

M.each_with_index do |m, c|
  f, ws = resolve(train_set, m)
  df_ws["M=#{m}"] = Daru::Vector.new(ws, name: "M=#{m}")
  
  plot = Nyaplot::Plot.new
  sc = plot.add_with_df(train_set.to_nyaplotdf, :scatter, :x, :y)
  sc.title("train_set")
  sc.color('blue')
  
  linex = (0..1).step(1.0 / (101 - 1)).to_a
  liney = linex.map do |x|
    Math.sin(2 * Math::PI * x)
  end
  line_answer = plot.add(:line, linex, liney)
  line_answer.title('answer')
  line_answer.color('green')
  
  liney = linex.map do |x|
    f.call(x)
  end
  line_erms = plot.add(:line, linex, liney)
  line_erms.title("E(RMS#{sprintf("%.2f", rms_error(train_set, f))})")
  line_erms.color('red')

  plot.configure do
    x_label("M=#{m}")
    y_label('')
    xrange([-0.05, 1.05])
    yrange([-1.5, 1.5])
    legend(true)
    height(300)
    width(490)
  end
  
  fig.add(plot)
end

puts 'Table ot the coefficients'
puts Daru::DataFrame.new(df_ws).inspect

fig.show

df = Daru::DataFrame.new({m: [], 'Training set': [], 'Test set': []})  
10.times do |m|
  f, ws = resolve(train_set, m)
  train_error = rms_error(train_set, f)
  test_error = rms_error(test_set, f)
  df.add_row(Daru::Vector.new([m, train_error, test_error], index: [:m, 'Training set'.to_sym, 'Test set'.to_sym]))
end

df.plot(type: [:line, :line], x: [:m, :m], y: ['Training set'.to_sym, 'Test set'.to_sym]) do |plot, diagrams|
  train_set_diagram = diagrams[0]
  test_set_diagram = diagrams[1]
  
  train_set_diagram.title('Training set')
  train_set_diagram.color('blue')
  test_set_diagram.title('Test set')
  test_set_diagram.color('green')
  
  plot.x_label('M')
  plot.y_label('RMS Error')
  plot.yrange([0, 0.9])
  plot.legend(true)
end
