require 'spec_helper'
require 'timecop'

describe Kuby::Docker::Metadata do
  let(:metadata) { definition.environment.docker.metadata }

  describe '#image_url' do
    subject { metadata.image_url }

    it { is_expected.to eq(docker_image_url) }

    context 'when no image URL is configured' do
      let(:docker_image_url) { nil }
      it { is_expected.to eq(definition.app_name) }
    end
  end

  describe '#image_host' do
    subject { metadata.image_host }

    it { is_expected.to eq(described_class::DEFAULT_REGISTRY_HOST) }

    context 'when the image URL contains an explicit host' do
      let(:docker_image_url) { 'registry.foo.com/foo/testapp' }

      it { is_expected.to eq('https://registry.foo.com') }
    end

    context 'when the image URL contains an explicit host with scheme' do
      let(:docker_image_url) { 'http://registry.foo.com/foo/testapp' }

      it { is_expected.to eq('http://registry.foo.com') }
    end
  end

  describe '#image_repo' do
    subject { metadata.image_repo }

    it { is_expected.to eq('foo/testapp') }

    context 'when the image URL contains an explicit host' do
      let(:docker_image_url) { 'registry.foo.com/foo/testapp' }

      it { is_expected.to eq('foo/testapp') }
    end
  end

  describe '#image_hostname' do
    subject { metadata.image_hostname }

    it { is_expected.to eq('www.docker.com') }

    context 'when the image URL contains an explicit host' do
      let(:docker_image_url) { 'registry.foo.com/foo/testapp' }

      it { is_expected.to eq('registry.foo.com') }
    end
  end

  describe '#tags' do
    subject { metadata.tags }

    it 'specifies the current timestamp tag and the default tag' do
      Timecop.freeze do
        expect(subject).to eq([
          Time.now.strftime('%Y%m%d%H%M%S'),
          Kuby::Docker::Metadata::LATEST_TAG
        ])
      end
    end
  end

  describe '#tag' do
    let(:tag) { make_ts_tag(Time.now) }

    subject { metadata.tag }

    context 'with no local or remote tags' do
      it 'raises an error' do
        expect { subject }.to raise_error(Kuby::Docker::MissingTagError)
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

  describe '#previous_tag' do
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

    subject { metadata.previous_tag(current_tag) }

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

  describe '#distro' do
    subject { metadata.distro }

    it { is_expected.to eq(Kuby::Docker::Metadata::DEFAULT_DISTRO) }

    context 'with a distro set manually' do
      before { metadata.distro = :alpine }

      it { is_expected.to eq(:alpine) }
    end
  end
end
