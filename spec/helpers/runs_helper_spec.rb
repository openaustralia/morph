# typed: false
# frozen_string_literal: true

require "spec_helper"

describe RunsHelper do
  context "when there are scraped domains" do
    let(:foo_domain) { mock_model(Domain, name: "foo.com") }
    let(:bar_domain) { mock_model(Domain, name: "bar.com") }
    let(:www_foo_domain) { mock_model(Domain, name: "www.foo.com") }
    let(:www_bar_domain) { mock_model(Domain, name: "www.bar.com") }
    let(:fiddle_domain) { mock_model(Domain, name: "fiddle.com") }

    describe "#scraped_domains_list" do
      describe "#with links" do
        it do
          expect(helper.scraped_domains_list([foo_domain], with_links: true)).to eq '<a target="_blank" rel="noopener" href="http://foo.com">foo.com</a>'
          expect(helper.scraped_domains_list([foo_domain], with_links: true)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain], with_links: true)).to eq '<a target="_blank" rel="noopener" href="http://foo.com">foo.com</a> and <a target="_blank" rel="noopener" href="http://bar.com">bar.com</a>'
          expect(helper.scraped_domains_list([foo_domain, bar_domain], with_links: true)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain], with_links: true)).to eq '<a target="_blank" rel="noopener" href="http://foo.com">foo.com</a>, <a target="_blank" rel="noopener" href="http://bar.com">bar.com</a>, and <a target="_blank" rel="noopener" href="http://www.foo.com">www.foo.com</a>'
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain], with_links: true)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain], with_links: true)).to eq '<a target="_blank" rel="noopener" href="http://foo.com">foo.com</a>, <a target="_blank" rel="noopener" href="http://bar.com">bar.com</a>, <a target="_blank" rel="noopener" href="http://www.foo.com">www.foo.com</a>, and 1 other domain'
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain], with_links: true)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain], with_links: true)).to eq '<a target="_blank" rel="noopener" href="http://foo.com">foo.com</a>, <a target="_blank" rel="noopener" href="http://bar.com">bar.com</a>, <a target="_blank" rel="noopener" href="http://www.foo.com">www.foo.com</a>, and 2 other domains'
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain], with_links: true)).to be_html_safe
        end
      end

      describe "#without links" do
        it do
          expect(helper.scraped_domains_list([foo_domain], with_links: false)).to eq "foo.com"
          expect(helper.scraped_domains_list([foo_domain], with_links: false)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain], with_links: false)).to eq "foo.com and bar.com"
          expect(helper.scraped_domains_list([foo_domain, bar_domain], with_links: false)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain], with_links: false)).to eq "foo.com, bar.com, and www.foo.com"
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain], with_links: false)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain], with_links: false)).to eq "foo.com, bar.com, www.foo.com, and 1 other domain"
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain], with_links: false)).to be_html_safe
        end

        it do
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain], with_links: false)).to eq "foo.com, bar.com, www.foo.com, and 2 other domains"
          expect(helper.scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain], with_links: false)).to be_html_safe
        end
      end
    end

    describe "#simplified_scraped_domains_list" do
      it do
        expect(helper.simplified_scraped_domains_list([foo_domain])).to eq "foo.com"
      end

      it do
        expect(helper.simplified_scraped_domains_list([foo_domain, bar_domain])).to eq "foo.com, bar.com"
      end

      it do
        expect(helper.simplified_scraped_domains_list([foo_domain, bar_domain, www_foo_domain])).to eq "foo.com, bar.com, www.foo.com"
      end

      it do
        expect(helper.simplified_scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain])).to eq "foo.com, bar.com, www.foo.com, and 1 other"
      end

      it do
        expect(helper.simplified_scraped_domains_list([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain])).to eq "foo.com, bar.com, www.foo.com, and 2 others"
      end
    end
  end
end
