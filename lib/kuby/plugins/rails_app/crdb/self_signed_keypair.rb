require 'openssl'

module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class SelfSignedKeypair
          def self.create(organization, common_name)
            key = OpenSSL::PKey::RSA.new(2048)

            cert = OpenSSL::X509::Certificate.new.tap do |cert|
              cert.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
              cert.serial = 1
              cert.subject = OpenSSL::X509::Name.parse("/O=#{organization},CN=#{common_name}")
              cert.issuer = cert.subject # root CA's are "self-signed"
              cert.public_key = key.public_key
              cert.not_before = Time.now
              cert.not_after = cert.not_before + 5 * 365 * 24 * 60 * 60 # 5 years validity
              ef = OpenSSL::X509::ExtensionFactory.new
              ef.subject_certificate = cert
              ef.issuer_certificate = cert
              cert.add_extension(ef.create_extension("keyUsage", "digitalSignature,keyEncipherment,nonRepudiation,keyCertSign,cRLSign", true))
              cert.add_extension(ef.create_extension("basicConstraints", "CA:true,pathlen:1", true))
              cert.sign(key, OpenSSL::Digest::SHA256.new)
            end

            Keypair.new(cert.to_s, key.to_s)
          end
        end
      end
    end
  end
end
