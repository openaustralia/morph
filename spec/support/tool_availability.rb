# typed: false
# frozen_string_literal: true

# Utilities to check for specified tool binaries
module ToolAvailability
  def tool_available?(tool_name)
    system("which #{tool_name} > /dev/null 2>&1")
  end

  def mysqldump_available?
    tool_available?("mysqldump")
  end

  def zstd_available?
    tool_available?("zstd")
  end

  def require_tool(tool_name, install_hint: nil)
    return if tool_available?(tool_name)

    message = "#{tool_name} is not installed."
    message += " Install with: #{install_hint}" if install_hint
    skip message
  end

  def require_zstd
    require_tool("zstd", install_hint: "apt-get install zstd")
  end
end
