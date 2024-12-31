### Notion Integration
#### Create your integration in Notion
The first step to building any integration (internal or public) is to create a new integration in Notion’s integrations dashboard: <https://www.notion.com/my-integrations>.
1. Click `+ New Integration`.
![Create integration](/docs/images/new_integration.png)
2. Enter the integration name and select the associated workspace for the new integration.
![Select workspace](/docs/images/new_integration_select_workspace.png)

#### Get your API secret
API requests require an API secret to be successfully authenticated.
1. Visit the Configuration tab to get your integration’s API secret (or “Internal Integration Secret”).
![API secret](/docs/images/get_api_key.png)
**Remember to keep your API secret a secret!**
Any value used to authenticate API requests should always be kept secret. Use environment variables and avoid committing sensitive data to your version control history.
If you do accidentally expose it, remember to “refresh” your secret.

#### Give your integration page permissions
The database that we’re about to create will be added to a parent Notion page in your workspace. For your integration to interact with the page, it needs explicit permission to read/write to that specific Notion page.

To give the integration permission, you will need to:
1. Go to the page with the database you created above.
2. Click on the ... More menu in the top-right corner of the page.
3. Scroll down to + Add Connections.
4. Search for your integration and select it.
5. Confirm the integration can access the page and all of its child pages.
![alt text](/docs/images/permissions.gif)
6. You can then limit the integrations permission to just `Read Contents`:
![alt text](/docs/images/permissions.png)

Now you're finally ready to config the gem!
