#!/usr/bin/ruby
require 'gosu'

class Numbered

  attr_accessor :x, :y, :angle

  def initialize(i, behaviour)
    @i = i
    @font = Gosu::Font.new(15)
    @behaviour = behaviour
  end

  def draw
    @font.draw("#{@i}", @x, @y, 0) if @behaviour[:show_numbers]
  end

end

class Average < Numbered

  def initialize(i, behaviour)
    super(i, behaviour)
    @image = Gosu::Image.new("arrow_blue.png")
    @x = @y = @angle = 0
  end

  def draw
    super
    @image.draw_rot(@x, @y, 1, @angle)
  end

end

class Boid < Numbered

  attr_accessor :x, :y, :angle

  def initialize(i, area, behaviour)
    super(i, behaviour)
    @behaviour = behaviour
    @image = Gosu::Image.new("arrow.png")
    @area = area
    @area.each_with_index { |l, i| self[i] = rand(l) }
    @angle = rand(360)
  end

  def steer_toward_angle(angle_average_position, factor = 1, turn_factor = 1) 
    delta_angle = Gosu::angle_diff(@angle, angle_average_position)
    if delta_angle < -10 * factor
      @angle -= @behaviour[:turn_angle]
    elsif delta_angle > 10 * factor
      @angle += @behaviour[:turn_angle]
    end
  end

  def steer_toward(average_position)
    steer_toward_angle(Gosu::angle(x, y, average_position[0], average_position[1]))
  end

  def avoid(boid)
    steer_toward_angle(Gosu::angle(0, 0, boid.x, boid.y), -1) if boid != self
  end

  def collide_walls()
    @x = @area[0] if @x < 0
    @y = @area[1] if @y < 0
    @x = 0 if @x > @area[0]
    @y = 0 if @y > @area[1]
  end
  
  def [](key)
    key == 0 ? @x : @y
  end

  def []=(key, value)
    key == 0 ?  @x = value : @y = value
  end

  def get_closest close_boids
    boids_by_distances = Hash[close_boids.map { |b| [b.distance(self), b] }]
    if boids_by_distances.size > 1
      closest_distance = boids_by_distances.keys.sort[1]
      [closest_distance, boids_by_distances[closest_distance]]
    else
      nil
    end
  end

  def update_angle(boids, average)
    close_boids = boids.select { |b| distance(b) < @behaviour[:visibility] }
    closest_distance, closest_boid = get_closest boids
    if not closest_distance.nil? and closest_distance < @behaviour[:avoid_distance]
      avoid(closest_boid)
    else
      average_position = close_boids.reduce([0,0]) { |a,b| [a[0] + b.x, a[1] + b.y] }
        .map {|x| x / close_boids.length }
      average_angle = close_boids.reduce(0) { |a,b| a + b.angle } / close_boids.length
      average.x = average_position[0]
      average.y =  average_position[1]
      average.angle = average_angle
      steer_toward(average_position)
      steer_toward_angle(average_angle)
    end
  end

  def move(boids, average)
    update_angle(boids, average)
    collide_walls
    @x += Gosu::offset_x(@angle, @behaviour[:speed])
    @y += Gosu::offset_y(@angle, @behaviour[:speed])

  end

  def draw
    super
    @image.draw_rot(@x, @y, 1, @angle)
  end

  def distance stuff
    Gosu::distance(x, y, stuff.x, stuff.y)
  end

end

class Boids < Gosu::Window

  def initialize width, height
    super(width, height)
    @behaviour = {turn_angle: 3.0, speed: 3.0, limit: 100, visibility: 200, avoid_distance: 5, show_average: false, show_numbers: false}
    @behaviour_modifiers = {turn_angle: [1, :a, :b],
                            speed: [1, :c, :d],
                            limit: [50, :e, :f],
                            visibility: [50, :g, :h],
                            avoid_distance: [5, :i, :j],
                            show_average: [false, :k],
                            show_numbers: [false, :l],
    }
    @font_size = 20
    @fonts = @behaviour_modifiers.map { |_| Gosu::Font.new(@font_size) }
    @boids = 1.upto(50).map { |i| Boid.new(i, [width, height], @behaviour) }
    @averages = 1.upto(50).map { |i| Average.new(i, @behaviour) }
  end

  def update
    @boids.each_with_index { |a, i| a.move(@boids, @averages[i]) }
  end

  def draw
    i = 0
    p = 0
    @behaviour.each_pair do |b, l|
      p b
      @fonts[i].draw("#{b} (#{@behaviour_modifiers[b].join(",")}) #{l}", 0, i * @font_size, 0)
      i += 1
    end
    @boids.each { |x| x.draw }
    @averages.each { |x| x.draw } if @behaviour[:show_average]
  end

  def button_down(id)
    close if id == Gosu::KbEscape
    @behaviour_modifiers.each_pair do |name, modifier|
      modifier = modifier.each_with_index.map { |x, i| i == 0 ? x : eval("Gosu::Kb#{x.to_s.upcase}") }
      if id == modifier[1]
        if modifier.size == 2
          @behaviour[name] = !@behaviour[name]
        else
          @behaviour[name] -= modifier[0]
        end
      elsif id == modifier[2]
        @behaviour[name] += modifier[0]
      end
    end
  end

end 

Boids.new((640*3).to_i, (480*2.5).to_i).show

