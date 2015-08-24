module ApplicationHelper
  def active_if_current(path)
    "active" if request.path == path
  end
end
