class Activity
  def self.format_seconds(seconds)
    hours, mins = seconds.divmod(3600)
    mins = mins / 60
    "#{hours.to_i} hr. #{mins.round} min."
  end

  def self.new_time(time)
    year, month, day = Time.now.year, Time.now.month, Time.now.day
    Time.new(year, month, day, *time.split(':'))
  end

  attr_accessor :name, :id, :start_time, :history

  def initialize(name, id)
    @name = name
    @id = id
    @history = []
  end

  def start(time)
    @start_time = Activity.new_time(time)
  end

  def running?
    @start_time
  end

  def stop(time)
    stop_time = Activity.new_time(time)
    seconds = stop_time - @start_time
    @history << { start_time: @start_time, stop_time: stop_time, seconds: seconds }
    @history.sort_by! { |item| item[:start_time] }
    @start_time = nil
  end

  def status
    running? ? 'running' : 'stopped'
  end

  def current_total
    Activity.format_seconds(Time.now - @start_time)
  end

  def history_total_seconds
    @history.map { |item| item[:seconds] }.sum
  end

  def history?
    !@history.empty?
  end
end
