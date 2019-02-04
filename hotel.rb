# Sahaj Hotel Automation
module Power
  LIGHT = 5
  AC    = 10
end

class Floor
  attr_accessor :number, :max_power_consumption, :main_corridors, :sub_corridors

  def initialize(floor_number, mc_count, sc_count)
    @number                = floor_number

    # main corridors are assumed to have lights and ACs to be switched ON always (5 + 10 = 15)
    # sub corridors are assumed to have ACs to be switched ON always (10)
    @max_power_consumption = (mc_count * (Power::LIGHT + Power::AC)) + (sc_count * Power::AC)

    @main_corridors        = []
    @sub_corridors         = []

    (0..(mc_count - 1)).each do |corridors_number|
      @main_corridors.push(Corridors.new(corridors_number, 'main'))
    end

    (0..(sc_count - 1)).each do |corridors_number|
      @sub_corridors.push(Corridors.new(corridors_number, 'sub'))
    end
  end

  def current_power_consumption
    return @main_corridors.collect do |mc|
      (mc.is_light_on ? 5 : 0) + (mc.is_ac_on ? 10 : 0)
    end.inject(0) { |sum, x| sum + x } +
    @sub_corridors.collect do |sc|
      (sc.is_light_on ? 5 : 0) + (sc.is_ac_on ? 10 : 0)
    end.inject(0) { |sum, x| sum + x }
  end

  def get_target_corridor(corridor_number, corridor_type)
    if corridor_type == 'main'
      return @main_corridors.select{ |corridor| corridor.number + 1 == corridor_number }.first
    elsif corridor_type == 'sub'
      return @sub_corridors.select{ |corridor| corridor.number + 1 == corridor_number }.first
    end
  end

  def switch_lights(target_corridor, corridor_type, found_movement)
    if corridor_type == 'main'
      puts found_movement ? 'Already light is ON in the main Corridor' : 'Main Corridor light cannot be switched off'
      return
    else
      corridors = @sub_corridors
    end
    if found_movement
      target_corridor.toggle_light
      target_corridor.toggle_movement
      if current_power_consumption() > @max_power_consumption
        corridors.select { |c| c != target_corridor }.each do |corridor|
          if corridor.is_ac_on && !corridor.is_movement
            corridor.toggle_ac
            break  
          end
        end
      else
        puts "Cannot exceed power limitations per floor"
        target_corridor.toggle_light
      end
    else
      target_corridor.toggle_light
      target_corridor.toggle_movement
      while current_power_consumption() < @max_power_consumption do
        corridors.select { |c| c != target_corridor }.each do |corridor|
          if !corridor.is_ac_on
            corridor.toggle_ac
          end
        end
      end
    end
  end
end

class Corridors
  attr_accessor :type, :is_light_on, :is_ac_on, :is_movement, :number

  def initialize(c_number, type)
    @type        = type
    @is_light_on = type == 'main'
    @is_ac_on    = true
    @number      = c_number
    @is_movement = false
  end

  def toggle_light
    @is_light_on = !@is_light_on
  end

  def toggle_ac
    @is_ac_on = !@is_ac_on
  end

  def toggle_movement
    @is_movement = !@is_movement
  end
end

class Hotel
  attr_accessor :floors

  def initialize(floors_count, mc_count, sc_count)
    @floors = []
    (0..(floors_count - 1)).each do |floor_number|
      @floors.push(Floor.new(floor_number, mc_count, sc_count))
    end
  end

  def switch_corridors(target_floor_number, target_corridor_number, corridor_type, found_movement)
    target_floor = @floors.select { |floor| floor.number + 1 == target_floor_number }.first

    target_corridor = target_floor.get_target_corridor(target_corridor_number, corridor_type)
    if target_corridor.is_light_on && found_movement
      puts "Already the light is ON in the given corridor!"
      return
    end

    if !target_corridor.is_light_on && !found_movement
      puts "Already the light is OFF in the given corridor!"
      return
    end

    target_floor.switch_lights(target_corridor, corridor_type, found_movement)
  end

  def print_hotel_status()
    @floors.each do |floor|
      puts "Floor #{floor.number + 1}"
      floor.main_corridors.each do |mc|
        puts "Main Corridor #{mc.number + 1} Light: #{mc.is_light_on ? 'ON' : 'OFF'} AC: #{mc.is_ac_on ? 'ON' : 'OFF'}"
      end
      floor.sub_corridors.each do |sc|
        puts "Sub Corridor #{sc.number + 1} Light: #{sc.is_light_on ? 'ON' : 'OFF'} AC: #{sc.is_ac_on ? 'ON' : 'OFF'}"
      end
    end
  end
end

# Driving Program for Hotel Automation
def process_input_signal(line)
  if (line =~ /^movement in floor (\d+), (sub|main) corridor (\d+)$/i)
    return [$1.to_i, $3.to_i, $2.downcase, true]
  elsif (line =~ /^no movement in floor (\d+), (sub|main) corridor (\d+) for a minute$/i)
    return [$1.to_i, $3.to_i, $2.downcase, false]
  end
end

count  = 1
file   = 'hotel-input.txt'
floors = main_count = sub_count = 0
File.readlines(file).each do |line|
  if count == 1
    floors = line.chomp.to_i    
  elsif count == 2
    main_count = line.chomp.to_i
  elsif count == 3
    sub_count = line.chomp.to_i      
  end
  count = count + 1
end
puts "Default lighting"
h = Hotel.new(floors, main_count, sub_count)
h.print_hotel_status
puts "\n"

signal_file = 'hotel-input-signal.txt'
File.readlines(signal_file).each do |line|
  puts line
  floor, corridor, type, found_movement = process_input_signal(line)
  h.switch_corridors(floor, corridor, type, found_movement)
  puts "-------------------------------"
  h.print_hotel_status
  puts "-------------------------------"

  puts "\n"
end
