# db/seeds.rb
# Database Teaching Assistant - Seed Data
# Le Wagon Standard - Clean, organized, and ready to use

puts "=" * 50
puts "🌱 Database Teaching Assistant - Seed Data"
puts "=" * 50

# ============================================================================
# CLEANING THE DATABASE
# ============================================================================

puts "\n🧹 Cleaning database..."
Stack.destroy_all

puts "✅ Database cleaned!"

# ============================================================================
# CREATING STACKS
# ============================================================================

puts "\n📚 Creating Stacks..."

stacks_data = [
  {
    title: "Setup Instructions",
    content: "To set up the project, first clone the repository and install dependencies with `bundle install`. Then configure the database with `rails db:create db:migrate`. Finally, add your API keys to the `.env` file.",
    name: "Setup Instructions",
    description: "Step-by-step guide to configure the development environment for the ParseDB project, including dependency installation, database setup, and environment variables configuration."
  },
  {
    title: "Schema Generator",
    content: "rails generate model User name:string email:string\nrails generate model Post title:string content:text user:references\nrails generate migration AddIndexToPosts created_at\nrails db:migrate",
    name: "Schema Generator",
    description: "Commands and examples for generating migrations and models in Rails. Learn how to create tables, relationships, and indexes using Rails generators."
  },
  {
    title: "Seed Example",
    content: "# Create categories\ncategories = ['Technology', 'Sports', 'Music']\ncategories.each do |cat|\n  Category.find_or_create_by!(name: cat)\nend\n\n# Create admin user\nUser.find_or_create_by!(email: 'admin@example.com') do |u|\n  u.password = 'password123'\n  u.password_confirmation = 'password123'\n  u.role = 'admin'\nend\n\n# Create sample posts\n5.times do |i|\n  Post.create!(\n    title: \"Sample Post #{i}\",\n    content: \"This is the content for sample post #{i}\",\n    user: User.first\n  )\nend",
    name: "Seed Example",
    description: "Practical examples of how to create seeds in Rails to populate the database with initial data, including users, posts, categories, and relationships using idempotent methods."
  }
]

puts "\n🌱 Creating #{stacks_data.count} stacks..."

stacks_data.each_with_index do |data, index|
  begin
    stack = Stack.find_or_create_by!(name: data[:name]) do |s|
      s.title = data[:title]
      s.content = data[:content]
      s.description = data[:description]
    end
    puts "  ✅ [#{index + 1}/#{stacks_data.count}] #{stack.name}"
  rescue => e
    puts "  ❌ Error creating #{data[:name]}: #{e.message}"
  end
end

# ============================================================================
# CREATE DEFAULT USER (OPTIONAL)
# ============================================================================

puts "\n👤 Checking for default user..."

unless User.exists?(email: 'teste@teste.com')
  User.create!(
    email: 'teste@teste.com',
    password: '123456',
    password_confirmation: '123456'
  )
  puts "  ✅ Default user created: teste@teste.com / 123456"
else
  puts "  ✅ Default user already exists"
end

# ============================================================================
# SUMMARY
# ============================================================================

puts "\n" + "=" * 50
puts "📊 SUMMARY"
puts "=" * 50
puts "  📚 Stacks created: #{Stack.count}"
puts "  👤 Users: #{User.count}"
puts "  🌱 Seed completed at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
puts "=" * 50
puts "\n✅ Database seeding completed successfully!"
