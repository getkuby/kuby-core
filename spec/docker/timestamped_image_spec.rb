# typed: false
require 'spec_helper'

describe Kuby::Docker::TimestampedImage do
  let(:dockerfile) { Kuby::Docker::Dockerfile.new }
  let(:image_url) { docker_image_url }
  let(:credentials) do
    Kuby::Docker::Credentials.new do
      username 'foo'
      password 'bar'
      email 'foo@bar.com'
    end
  end
  let(:image) { described_class.new(dockerfile, image_url, credentials) }

  describe '#current_version' do
    let(:tag) { make_ts_tag(Time.now) }

    subject { image.current_version&.main_tag }

    context 'with no local or remote tags' do
      it 'creates a new tag' do
        expect(subject).to match(/\d{14}/)
      end
    end

    context 'with an available remote tag' do
      before { docker_remote_client.tags << tag }

      it { is_expected.to eq(tag) }
    end

    context 'with an available local tag' do
      before do
        docker_cli.build(
          dockerfile: nil,
          image_url: docker_image_url,
          tags: [tag]
        )
      end

      it { is_expected.to eq(tag) }
    end

    context 'with multiple remote tags' do
      let(:time) { Time.now }

      before do
        docker_remote_client.tags +=
          [time - 5, time + 10, time - 10, time + 15].map do |t|
            make_ts_tag(t)
          end
      end

      it { is_expected.to eq(make_ts_tag(time + 15)) }
    end

    context 'with multiple local and remote tags' do
      let(:time) { Time.now }

      before do
        docker_remote_client.tags +=
          [time - 5, time + 10, time - 10, time + 15].map do |t|
            make_ts_tag(t)
          end

        docker_cli.build(
          dockerfile: nil,
          image_url: docker_image_url,
          tags: [time - 3, time + 6, time - 6, time + 18].map do |t|
            make_ts_tag(t)
          end
        )
      end

      it { is_expected.to eq(make_ts_tag(time + 18)) }
    end
  end

  describe '#previous_version' do
    let(:time) { Time.now }
    let(:current_tag) { make_ts_tag(time) }

    before do
      docker_remote_client.tags << current_tag
      docker_cli.build(
        dockerfile: nil,
        image_url: docker_image_url,
        tags: [current_tag]
      )
    end

    subject { image.previous_version(current_tag)&.main_tag }

    context 'with no previous local or remote tag' do
      it 'raises an error' do
        expect { subject }.to raise_error(Kuby::Docker::MissingTagError)
      end
    end

    context 'with an available previous remote tag' do
      let(:previous_tag) { make_ts_tag(time - 5) }

      before { docker_remote_client.tags << previous_tag }

      it { is_expected.to eq(previous_tag) }
    end

    context 'with an available previous local tag' do
      let(:previous_tag) { make_ts_tag(time - 5) }

      before do
        docker_cli.build(
        dockerfile: nil,
        image_url: docker_image_url,
        tags: [previous_tag]
        )
      end

      it { is_expected.to eq(previous_tag) }
    end
  end
end