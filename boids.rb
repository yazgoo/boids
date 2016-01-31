#!/usr/bin/ruby
require 'gosu'

class BoidLimits
end

class Boid
  attr_accessor :x, :y, :angle
  def initialize(width, height)
    @image = Gosu::Image.new("arrow.png")
    @width = width
    @height = height
    @x = rand(width)
    @y = rand(height)
    @vel_x = 0
    @vel_y = 0
    @angle = rand(360)
    @score = 0
    @turn_angle = 3.0
    @speed = 3.0
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def turn_left
    @angle -= @turn_angle
  end

  def turn_right
    @angle += @turn_angle
  end

  def accelerate
    @vel_x += Gosu::offset_x(@angle, @speed)
    @vel_y += Gosu::offset_y(@angle, @speed)
  end

  def steer_toward_angle(angle_average_position, factor = 1, turn_factor = 1) 
    delta_angle = Gosu::angle_diff(@angle, angle_average_position)
    if delta_angle < -10 * factor
      turn_left
    elsif delta_angle >= 10 * factor
      turn_right
    end
  end

  def steer_toward(average_position)
    steer_toward_angle(Gosu::angle(@x, @y, average_position[0], average_position[1]))
  end

  def avoid(boid)
    steer_toward_angle(Gosu::angle(@x, @y, boid.x, boid.y), -1) if boid != self
  end

  def collide_walls()
    limit = 100
    @angle = (@angle - 180) if @x > @width - limit or @y > @height - limit or @y < limit or @x < limit
    @x = @width - limit - 5 if @x > @width - limit
    @y = @height - limit - 5 if @y > @height - limit
    @x = limit + 5 if @x < limit
    @y = limit + 5 if @y < limit
  end

  def do_move()

    @vel_x = @vel_y = 0

    collide_walls

    accelerate


    @x += @vel_x
    @y += @vel_y

  end

  def move(close_boids)

    a = self
    boids_by_distances = Hash[close_boids.map { |b| [b.distance(a), b] }]
    if boids_by_distances.size > 0
      closest_distance = boids_by_distances.keys.sort.first
      closest_boid = boids_by_distances[closest_distance]
      if closest_distance < 5
        avoid(closest_boid)
      else
        average_position = [close_boids.reduce(0) { |a, b| a + b.x } / close_boids.length,
                            close_boids.reduce(0) { |a, b| a + b.y } / close_boids.length]
        @@average ||= 0
        @@average_n ||= 0
        @@average += average_position[0]
        @@average_n += 1
        p @@average / @@average_n
        average_angle = close_boids.reduce(0) { |a, b| a + b.angle } / close_boids.length
        steer_toward(average_position)
        steer_toward_angle(average_angle)
      end
    end

    do_move 

  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

  def distance stuff
    Gosu::distance(x, y, stuff.x, stuff.y)
  end

end

class Boids < Gosu::Window
  def initialize
    @width = (640*3).to_i
    @height = (480*2.5).to_i
    super(@width, @height)
    self.caption = 'Boids'
    @boids = 1.upto(50).map { Boid.new(@width, @height) }
  end
  def update
    @boids.each do |a|
      close_boids = @boids.select { |b| b.distance(a) < 200 and b != a }
      a.move(close_boids)
    end
  end
  def draw
    @boids.each { |x| x.draw }
  end
  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end 
Boids.new.show

