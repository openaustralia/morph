# This is a template for a Python scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# import scraperwiki
# import lxml.html
#
# # Read in a page
# html = scraperwiki.scrape("http://foo.com")
#
# # Find something on the page using css selectors
# root = lxml.html.fromstring(html)
# root.cssselect("div[align='left']")
#
# # Write out to the sqlite database using scraperwiki library
# scraperwiki.sqlite.save(unique_keys=['name'], data={"name": "susan", "occupation": "software developer"})
#
# # An arbitrary query against the database
# scraperwiki.sql.select("* from data where 'name'='peter'")

# You don't have to do things with the ScraperWiki and lxml libraries.
# You can use whatever libraries you want: https://morph.io/documentation/python
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".

import sqlite3
import lxml.html
from urllib.request import urlopen

class Scraper:
    @staticmethod
    def run():
        # Read in a page
        with urlopen("https://example.com") as response:
            html = response.read()

        # Find something on the page using css selectors
        root = lxml.html.fromstring(html)

        # Create database connection
        conn = sqlite3.connect('data.sqlite')
        cursor = conn.cursor()

        # Create table if it doesn't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS data (
                name TEXT PRIMARY KEY
            )
        ''')

        for h1 in root.cssselect("h1"):
            value = h1.text_content().strip()
            # Write out to the sqlite database
            cursor.execute('''
                INSERT OR REPLACE INTO data (name) VALUES (?)
            ''', (value,))

        conn.commit()

        # An arbitrary query against the database
        cursor.execute("SELECT rowid AS id, name FROM data ORDER BY rowid DESC LIMIT 3")
        rows = cursor.fetchall()
        for row in rows:
            print(f"{row[0]}: {row[1]}")

        conn.close()

# Run the scraper whilst allowing this file to be imported in tests without auto-execution
if __name__ == '__main__':
    Scraper.run()
