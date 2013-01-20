# vim:ft=ruby
#
# How to use
#
#     $ gem i watchr # if you don't have
#     $ watchr watchr

watch '^.*\.lhs$' do |md|
  `rake compile`
  puts "Compiled"
end
