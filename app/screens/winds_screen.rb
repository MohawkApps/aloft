class WindsScreen < PM::TableScreen
  title "Winds Aloft"
  refreshable

  def on_load
    rmq.stylesheet = WindsStylesheet

    view.rmq.apply_style :root_view
    table_view.rmq.apply_style :winds_table

    self.navigationController.navigationBar.translucent = false
    self.automaticallyAdjustsScrollViewInsets = false
    self.edgesForExtendedLayout = UIRectEdgeNone

    set_nav_bar_right_button UIImage.imageNamed('wind'), action: :open_stations
    set_nav_bar_left_button UIImage.imageNamed('settings'), action: :open_stations
  end

  def on_appear
    open_stations(false, false)
    setTitle('Winds Aloft', subtitle:"at #{App::Persistence['station']}")
    get_winds
  end

  def open_stations(animated = true, force = true)
    if App::Persistence['station'].nil? || force
      open_modal StationsScreen.new(nav_bar: true), animated: animated
    end
  end

  def table_data
    [{
      cells: (wind_heights.enum_for(:each_with_index).map { |k, i| cell(i, k) }) << info_cell
    }]
  end

  def on_refresh ; get_winds ; end

  def cell_height
    @cell_h ||= (table_view.size.height - info_cell_height) / wind_heights.count
  end

  def cell_background_color(index)
    %w(18c1e0 29cae9 40d0eb 57d6ed 6edbf0 85e1f2 9ce7f4 b3ecf7 caf2f9)[index].to_color
  end

  def get_winds
    return unless App::Persistence['station']

    Winds.client.at_station(App::Persistence['station']) do |w|
      @winds = w.last
      end_refreshing
      update_table_data
    end
  end

  def wind_heights
    %w(3 6 9 12 18 24 30 34 39).map{ |h| h.to_i * 1000 }.reverse
  end

  def base_cell
    {
      height: cell_height,
      editing_style: :none,
      selection_style: UITableViewCellSelectionStyleNone,
      cell_class: WindCell,
      azimuth: azimuth_image,
      bearing: nil,
      # speed: nil,
      # temp: nil
    }
  end

  def cell(index, key)
    unless @winds.nil?
      data = @winds[key.to_s]
      base_cell.merge({
        background_color: cell_background_color(index),
        altitude: "#{number_with_delimiter(key)}ft",
        bearing: data['bearing'],
        # speed: "#{data['speed']} knots",
        # temperature: "#{data['temp']}°C"
      })
    else
      base_cell.merge({
        background_color: cell_background_color(index),
        altitude: "#{number_with_delimiter(key)}ft",
      })
    end
  end

  def info_cell
    {
      title: "This is a test",
      height: info_cell_height,
      editing_style: :none,
      selection_style: UITableViewCellSelectionStyleNone,
    }
  end

  def info_cell_height
    10
  end

  def azimuth_image
    @ai ||= UIImage.imageNamed('arrow').imageWithRenderingMode(UIImageRenderingModeAlwaysTemplate)
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

end