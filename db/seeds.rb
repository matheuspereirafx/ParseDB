# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
# Database Teaching Assistant - Seed, Schema e Database Challenges
# Padrão Le Wagon - Limpo, organizado e pronto para usar

puts "=" * 50
puts "🌱 Database Teaching Assistant - Seed Data"
puts "=" * 50

# ============================================================================
# LIMPEZA DO BANCO
# ============================================================================

puts "\n🧹 Limpando banco de dados..."
Stack.destroy_all
#Chat.destroy_all
#Message.destroy_all
puts "✅ Banco limpo!"


puts "Criando Stacks..."

Stack.create!(
  title: "Instrução de Setup",
  content: "Para configurar o projeto, primeiro clone o repositório..."
)

Stack.create!(
  title: "Schema Generator",
  content: "rails generate model User name:string email:string..."
)

Stack.create!(
  title: "Seed Example",
  content: "User.create!(name: 'João Silva', email: 'joao@example.com'...)"
)

puts "✅ 3 Stacks criados com sucesso!"
