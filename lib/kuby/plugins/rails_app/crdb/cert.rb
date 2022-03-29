require 'base64'
require 'openssl'

module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class Cert
          attr_reader :base_path, :master_key, :common_name, :creator_block

          def initialize(base_path, master_key, common_name, &creator_block)
            @base_path = base_path
            @master_key = master_key
            @common_name = common_name
            @creator_block = creator_block
          end

          def cert_path
            @cert_path ||= File.join(base_path, "database_#{common_name}.crt")
          end

          def key_path
            @key_path ||= File.join(base_path, "database_#{common_name}.key.enc")
          end

          def keypair
            return @keypair if @keypair

            if File.exist?(cert_path)
              cert = File.read(cert_path)
              key = decrypt(File.read(key_path))
              @keypair = Keypair.new(cert, key)
            else
              @keypair = creator_block.call
              persist!
            end

            @keypair
          end

          def persist!
            File.write(cert_path, keypair.cert)
            File.write(key_path, encrypt(keypair.key))
          end

          def cert
            keypair.cert
          end

          def key
            keypair.key
          end

          private

          def encrypt(value)
            cipher = new_cipher
            cipher.encrypt
            cipher.key = master_key
            iv = cipher.random_iv
            encrypted_data = cipher.update(value)
            encrypted_data << cipher.final
            "#{::Base64.strict_encode64(encrypted_data)}--#{::Base64.strict_encode64(iv)}"
          end

          def decrypt(encryped_data)
            cipher = new_cipher
            encrypted_data, iv = encryped_data.split('--').map { |v| ::Base64.strict_decode64(v) }

            cipher.decrypt
            cipher.key = master_key
            cipher.iv = iv

            cipher.update(encrypted_data).tap do |decrypted_data|
              decrypted_data << cipher.final
            end
          end

          def new_cipher
            OpenSSL::Cipher.new('aes-256-cbc')
          end
        end
      end
    end
  end
end
