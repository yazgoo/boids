#!/usr/bin/ruby
require 'gosu'


class Boid

  attr_accessor :x, :y, :angle

  def initialize(area, behaviour)
    super()
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
    elsif delta_angle >= 10 * factor
      @angle += @behaviour[:turn_angle]
    end
  end

  def steer_toward(average_position)
    steer_toward_angle(Gosu::angle(@x, @y, average_position[0], average_position[1]))
  end

  def avoid(boid)
    steer_toward_angle(Gosu::angle(@x, @y, boid.x, boid.y), -1) if boid != self
  end

  def collide_walls()
    @angle = (@angle - 180) if @x > @area[0] - @behaviour[:limit] or @y > @area[1] - @behaviour[:limit] or @y < @behaviour[:limit] or @x < @behaviour[:limit]
    2.times do |i|
      self[i] = @area[i] - @behaviour[:limit] - 5 if self[i] > @area[i] - @behaviour[:limit]
      self[i] = @behaviour[:limit] + 5 if self[i] < @behaviour[:limit]
    end
  end
  
  def [](key)
    key == 0 ? @x : @y
  end

  def []=(key, value)
    key == 0 ?  @x = value : @y = value
  end

  def update_angle(boids)
    close_boids = boids.select { |b| distance(b) < @behaviour[:visibility] and b != self }
    boids_by_distances = Hash[close_boids.map { |b| [b.distance(self), b] }]
    if boids_by_distances.size > 0
      closest_distance = boids_by_distances.keys.sort.first
      closest_boid = boids_by_distances[closest_distance]
      if closest_distance < 5
        avoid(closest_boid)
      else
        average_position = close_boids.reduce([0,0]) { |a,b| [a[0] + b.x, a[1] + b.y] }
          .map {|x| x / close_boids.length }
        average_angle = close_boids.reduce(0) { |a, b| a + b.angle } / close_boids.length
        steer_toward(average_position)
        steer_toward_angle(average_angle)
      end
    end
  end

  def move(boids)
    update_angle(boids)
    collide_walls
    @x += Gosu::offset_x(@angle, @behaviour[:speed])
    @y += Gosu::offset_y(@angle, @behaviour[:speed])

  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

  def distance stuff
    Gosu::distance(x, y, stuff.x, stuff.y)
  end

end

class Boids < Gosu::Window

  def initialize width, height
    super(width, height)
    @behaviour = {turn_angle: 3.0, speed: 3.0, limit: 100, visibility: 200}
    @behaviour_modifiers = {turn_angle: [1, :a, :b],
                            speed: [1, :c, :d],
                            limit: [50, :e, :f],
                            visibility: [50, :g, :h]}
    @font_size = 20
    @fonts = @behaviour_modifiers.map { |_| Gosu::Font.new(@font_size) }
    @boids = 1.upto(50).map { Boid.new([width, height], @behaviour) }
  end

  def update
    @boids.each { |a| a.move(@boids) }
  end

  def draw
    i = 0
    p = 0
    @behaviour.each_pair do |b, l|
      @fonts[i].draw("#{b} (#{@behaviour_modifiers[b][1]},#{@behaviour_modifiers[b][2]}) #{l}", 0, i * @font_size, 0)
      i += 1
    end
    @boids.each { |x| x.draw }
  end

  def button_down(id)
    close if id == Gosu::KbEscape
    @behaviour_modifiers.each_pair do |name, modifier|
      modifier = modifier.each_with_index.map { |x, i| i == 0 ? x : eval("Gosu::Kb#{x.to_s.upcase}") }
      if id == modifier[1]
        @behaviour[name] -= modifier[0]
      elsif id == modifier[2]
        @behaviour[name] += modifier[0]
      end
    end
  end

end 

Boids.new((640*3).to_i, (480*2.5).to_i).show

