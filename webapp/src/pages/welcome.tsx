import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
// import Toolbar from "@mui/material/Toolbar";

// import ImageListItem from "@material-ui/core/ImageListItem";


import i18n from "i18next";
import { useTranslation } from "react-i18next";
import Grid from "@mui/material/Grid";
import Item from "@mui/material/ListItem";
import Button from "@mui/material/Button";
import { Link } from "react-router-dom";


export const renderWelcome = () => {
    const { t } = useTranslation('translation')
    
    console.log("Welcome render")

    i18n.addResource('gb', 'translation', 'welcome', 'Blood Parameters Storage System (BPS2)');
    i18n.addResource('de', 'translation', 'welcome', 'BPS2');
    i18n.addResource('pl', 'translation', 'welcome', 'BPS2');

    i18n.addResource('gb', 'translation', 'pressure', 'Pressure');
    i18n.addResource('de', 'translation', 'pressure', 'Druck');
    i18n.addResource('pl', 'translation', 'pressure', 'Ciśnienie');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
        <Grid container spacing={2}>
  <Grid item xs={8}>
    <Item>
        <Link to="/pressure">
        <Button variant="outlined">
            {t("pressure")}
        </Button>
        </Link>
        xs=8</Item>
  </Grid>
  <Grid item xs={4}>
    <Item>
    <Link to="/sugar">
        <Button variant="outlined">
            {t("sugar")}
        </Button>
        </Link>
        xs=4</Item>
  </Grid>
  <Grid item xs={4}>
    <Item>xs=4</Item>
  </Grid>
  <Grid item xs={8}>
    <Item>xs=8</Item>
  </Grid>
</Grid>
            {/*<Toolbar> */ }
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('welcome')}
                    {/* <Link style={{ textDecoration: "none", color: "white" }} to="/pressure">{t("pressure")}</Link> */}
            
                </Typography>
            {/* </Toolbar> */}
        </Container>
        </AppBar>
    )
}

