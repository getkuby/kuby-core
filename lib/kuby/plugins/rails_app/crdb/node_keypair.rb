module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class NodeKeypair
          def self.create(ca_cert, ca_key, organization, common_name, alt_names)
            key = OpenSSL::PKey::RSA.new(2048)
            root_ca = OpenSSL::X509::Certificate.new(ca_cert)
            root_key = OpenSSL::PKey.read(ca_key)

            cert = OpenSSL::X509::Certificate.new.tap do |cert|
              cert.version = 2
              cert.serial = 1
              cert.subject = OpenSSL::X509::Name.parse("/O=#{organization}/CN=#{common_name}")
              cert.issuer = root_ca.subject # root CA is the issuer
              cert.public_key = key.public_key
              cert.not_before = Time.now
              cert.not_after = cert.not_before + 5 * 365 * 24 * 60 * 60  # valid for 5 years
              ef = OpenSSL::X509::ExtensionFactory.new
              ef.subject_certificate = cert
              ef.issuer_certificate = root_ca
              cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature,keyEncipherment', true))
              cert.add_extension(ef.create_extension('extendedKeyUsage', 'clientAuth,serverAuth', false))
              cert.add_extension(ef.create_extension('subjectAltName', alt_names.join(',')))
              cert.sign(root_key, OpenSSL::Digest::SHA256.new)
            end

            Keypair.new(cert.to_s, key.to_s)
          end
        end
      end
    end
  end
end
